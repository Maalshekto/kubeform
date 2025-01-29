#!/bin/bash
# scripts/bastion.sh

# Exit immediately if a command exits with a non-zero status
set -e

# Define the hostname
hostnamectl set-hostname ${hostname}-${trigram}

# Add the hostname to /etc/hosts
echo "127.0.0.1   ${hostname}-${trigram}" >> /etc/hosts

# Add the SSH public key
mkdir -p /home/ubuntu/.ssh
echo "${PUBLIC_KEY}" > /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys

# Update package lists and upgrade existing packages
apt-get update && apt-get upgrade -y

# Install necessary tools (e.g., AWS CLI, htop)
apt-get install -y htop

apt update && apt upgrade -y

# Install Docker
apt install -y docker.io
systemctl enable docker
systemctl start docker

# Configure Traefik
mkdir -p /etc/traefik
cat <<EOF > /etc/traefik/traefik.toml
# Création du fichier traefik.toml (config statique)
${traefik_conf}
EOF

# Dump the dynamic configuration to a file
cat <<EOF > /etc/traefik/dynamic_conf.toml
${dynamic_conf}
EOF

# Erase eventual Windows line endings
sed -i 's/\r$//g' /etc/traefik/*.toml

docker run -d --name traefik \
  -p 80:80 \
  -p 8080:8080 \
  -v /etc/traefik/:/etc/traefik/ \
  traefik \
  --api.dashboard=true \
  --api.insecure=true \
  --entrypoints.web.address=:80 \
  --providers.docker=true