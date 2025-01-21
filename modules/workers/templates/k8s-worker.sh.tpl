#!/bin/bash
# scripts/k8s-node.sh
set -e
# Redirect all output to a log file
exec > >(tee /var/log/k8s-worker.log|logger -t k8s-worker -s 2>/dev/console) 2>&1

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
echo "Installing Kubernetes version: $version"
major_minor=$(echo "$version" | cut -d '.' -f 1,2)
echo "Major and minor version: $major_minor"
sudo curl -fsSL "https://pkgs.k8s.io/core:/stable:/v$major_minor/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$major_minor/deb/ / " | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
# Get exact version of kubeadm, kubectl and kubelet
exact_vers=`apt-cache madison kubeadm | grep $version | awk '{print $3}' | head -1`
echo "Exact version of kubeadm, kubectl and kubelet: $exact_vers"
sudo apt-get install -y kubelet=$exact_vers kubeadm=$exact_vers kubectl=$exact_vers
sudo apt-mark hold kubelet kubeadm kubectl

sudo sysctl --system

# Attendre que la commande kubeadm join soit disponible via HTTP sur le controlplane
CONTROLPLANE=${CONTROLPLANE_IP}  # Injecté par Terraform
JOIN_CMD_URL="http://${CONTROLPLANE_IP}:8080/join_command.sh"

# Attendre que le controlplane soit prêt et que le fichier de jointure soit disponible
until curl -s $JOIN_CMD_URL -o /tmp/join_command.sh; do
  echo "Attente que le controlplane soit prêt pour fournir la commande de jointure..."
  sleep 10
done

# Lire la commande de jointure depuis le fichier
JOIN_CMD=$(cat /tmp/join_command.sh)

# Exécuter la commande de jointure
sudo $JOIN_CMD

# Redémarrer Docker et kubelet pour s'assurer qu'ils fonctionnent correctement
sudo systemctl restart docker
sudo systemctl restart kubelet