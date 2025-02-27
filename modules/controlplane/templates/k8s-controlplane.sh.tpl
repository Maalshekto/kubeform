#!/bin/bash
# scripts/k8s-node.sh

set -e
# Redirect all output to a log file
exec > >(tee /var/log/k8s-controlplane.log|logger -t k8s-controlplane -s 2>/dev/console) 2>&1

# Define the hostname
hostnamectl set-hostname ${hostname}-${cluster_name}

# Add the hostname to /etc/hosts
echo "127.0.0.1   ${hostname}-${cluster_name}" >> /etc/hosts

# Ajouter la clé publique SSH
mkdir -p /home/ubuntu/.ssh
echo "${PUBLIC_KEY}" > /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Update and install prerequisites
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

# Docker installation
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc]  https://download.docker.com/linux/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker

# containerd configuration
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml
systemctl restart containerd


# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system

# Configurer les modules kernel nécessaires
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# Install Kubernetes
version=${k8s_version}
echo "[DEBUG] Installing Kubernetes version: $version"
major_minor=$(echo "$version" | cut -d '.' -f 1,2)
echo "[DEBUG] Major minor version: $major_minor"
sudo curl -fsSL "https://pkgs.k8s.io/core:/stable:/v$major_minor/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$major_minor/deb/ / " | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
# Get exact version of kubeadm, kubectl and kubelet
exact_vers=`apt-cache madison kubeadm | grep $version | awk '{print $3}' | head -1`
echo "[DEBUG] Exact version: $exact_vers"
sudo apt-get install -y kubelet=$exact_vers kubeadm=$exact_vers kubectl=$exact_vers
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize the Kubernetes cluster
sudo kubeadm init --pod-network-cidr=10.44.0.0/16 --upload-certs

# Configure kubectl for the ubuntu user
sudo -u ubuntu -i bash -c "
  mkdir -p /home/ubuntu/.kube;
  sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config;
  sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config;   
"
# And for root user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

case "${CNI}" in 
  "calico")
    # Install Calico in IPIP mode Always
    curl "https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/calico.yaml" -O
    kubectl apply -f calico.yaml
    ;;
    
  # TODO: Still Work in Progress - Installation of Cilium
  "cilium")
    # Install Cilium Cli
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    CLI_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/$CILIUM_CLI_VERSION/cilium-linux-$CLI_ARCH.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-$CLI_ARCH.tar.gz.sha256sum
    sudo tar xzvfC cilium-linux-$CLI_ARCH.tar.gz /usr/local/bin
    rm cilium-linux-$CLI_ARCH.tar.gz{,.sha256sum}
    cilium install --kubeconfig $HOME/.kube/config --set aws.interface-exclusion-regex="^ens5$"
    ;;

  # TODO: Eventually add support for other CNIs
  *)
    echo "[ERROR] No CNI specified"
    ;;
esac

# Wait for the controlplane node to be ready
kubectl wait node $(hostname) --for=condition=Ready --timeout=600s
echo "[DEBUG] Generating join command for the worker nodes..."
KUBEADM_JOIN_CMD=$(kubeadm token create --print-join-command --ttl 24h)

# Save the join command to a file for the worker nodes
echo "$KUBEADM_JOIN_CMD" > /tmp/join_command.sh
sudo -u ubuntu bash -c "nohup python3 -m http.server 8080 --directory /tmp &"

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Wait for the cluster including workers to be ready
nb_node_ready=`kubectl get nodes --no-headers=true | awk '{print $2}' | grep  'Ready' | wc -l`
echo "[DEBUG] Number of nodes ready: $nb_node_ready"

while [ $nb_node_ready -lt ${NUM_WORKERS + 1} ]; do
  echo "[DEBUG] Waiting for all nodes to be ready..."
  sleep 10
  nb_node_ready=`kubectl get nodes --no-headers=true | awk '{print $2}' | grep  'Ready' | wc -l`
  echo "[DEBUG] Number of nodes ready: $nb_node_ready"
done

# Fix coredns configmap for aws
echo "[DEBUG] Patching CoreDNS configuration to optimize cache and performance..."
kubectl patch cm coredns -n kube-system --type='merge' -p "{
  \"data\": {
    \"Corefile\": \".:53 {\\n\
      errors\\n\
      health\\n\
      ready\\n\
      kubernetes cluster.local in-addr.arpa ip6.arpa {\\n\
        pods insecure\\n\
        fallthrough in-addr.arpa ip6.arpa amazonaws.com\\n\
        ttl 30\\n\
      }\\n\
      prometheus :9153\\n\
      forward . /etc/resolv.conf {\\n\
        max_concurrent 1000\\n\
      }\\n\
      cache 60\\n\
      loop\\n\
      reload\\n\
      loadbalance round_robin\\n\
    }\"
  }
}"

echo "[DEBUG] Restarting CoreDNS to apply changes..."
kubectl rollout restart deployment coredns -n kube-system

# Install zsh and oh-my-zsh
sudo apt-get install -y zsh
sudo -u ubuntu bash -c 'yes y | CHSH=yes RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
# Vérifier si "kubectl" est déjà dans le fichier; si non, on l’ajoute
grep -q "kubectl" /home/ubuntu/.zshrc || sed -i '/^plugins=(/ s/)/ kubectl)/' /home/ubuntu/.zshrc
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="${ZSH_THEME}"/' /home/ubuntu/.zshrc
sudo chsh -s /usr/bin/zsh ubuntu

# TODO: Make it work with Traefik in order to expose services without NodePort
# Helm install Ingress Nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx   --namespace ingress-nginx --create-namespace   --set controller.publishService.enabled=true

# Create shell jenkins.sh file
cat <<EOF > /home/ubuntu/jenkins.sh
${jenkins_install}
EOF

# Erase Windows line endings, set correct rights and execute the script
sed -i 's/\r$//g' /home/ubuntu/jenkins.sh
chmod 755 /home/ubuntu/jenkins.sh
chown ubuntu:ubuntu /home/ubuntu/jenkins.sh
sudo -u ubuntu bash -c "/home/ubuntu/jenkins.sh"