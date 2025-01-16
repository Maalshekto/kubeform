#!/bin/bash
# scripts/k8s-node.sh

# Define the hostname
hostnamectl set-hostname ${hostname}

# Add the hostname to /etc/hosts
echo "127.0.0.1   ${hostname}" >> /etc/hosts

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
sudo curl -fsSL "https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ / " | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize the Kubernetes cluster
sudo kubeadm init --pod-network-cidr=10.44.0.0/16 --upload-certs

# Configure kubectl for the ubuntu user
sudo -u ubuntu -i bash -c "
  mkdir -p /home/ubuntu/.kube;
  sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config;
  sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config;   
"

# Install Calico
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
curl "https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/calico.yaml" -O
kubectl apply -f calico.yaml

# Wait for the master node to be ready
kubectl wait node $(hostname) --for=condition=Ready --timeout=600s
echo "Generating join command for the worker nodes..."
KUBEADM_JOIN_CMD=$(kubeadm token create --print-join-command --ttl 24h)

# Save the join command to a file for the worker nodes
echo "$KUBEADM_JOIN_CMD" > /tmp/join_command.sh
sudo -u ubuntu bash -c "nohup python3 -m http.server 8080 --directory /tmp &"

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Wait for the cluster including workers to be ready
do 
  nb_node_ready=`kubectl get nodes --no-headers=true | awk '{print $2}' | grep  'Ready' | wc -l`
  echo "Number of nodes ready: $nb_node_ready"
  sleep 5
done while [ $nb_node_ready -lt ${NUM_WORKERS + 1} ]


# Helm install Ingress Nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx   --namespace ingress-nginx --create-namespace   --set controller.publishService.enabled=true
