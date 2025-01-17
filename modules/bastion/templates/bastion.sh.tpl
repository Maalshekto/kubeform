#!/bin/bash
# scripts/bastion.sh

# Exit immediately if a command exits with a non-zero status
set -e

# Define the hostname
hostnamectl set-hostname ${hostname}-${cluster_name}

# Add the hostname to /etc/hosts
echo "127.0.0.1   ${hostname}-${cluster_name}" >> /etc/hosts

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

# Install Docker Compose
curl -SL https://github.com/docker/compose/releases/download/v2.32.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose