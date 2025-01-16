# terraform-test/variables.tf

variable "aws_region" {
  description = "La région AWS où déployer les ressources."
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "CIDR pour le VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR pour le subnet public."
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR pour le subnet privé."
  default     = "10.0.2.0/24"
}

variable "bastion_ami" {
  description = "AMI pour l'instance bastion (Ubuntu 20.04)."
  default     = "ami-08b426ca1360eb488" # Remplacez par l'AMI appropriée pour votre région
}

variable "bastion_ingress_user_public_ip" {
  description = "Adresse IP publique de l'utilisateur pour l'accès SSH au bastion."
  default     = "YOUR_PUBLIC_IP/32"
}

variable "k8s_ami" {
  description = "AMI pour les instances Kubernetes (Ubuntu 20.04)."
  default     = "ami-08b426ca1360eb488" # Remplacez par l'AMI appropriée pour votre région
}

variable "instance_type_bastion" {
  description = "Type d'instance pour le bastion."
  default     = "t3.small"
}

variable "instance_type_master" {
  description = "Type d'instance pour le control-plane."
  default     = "t3.medium"
}

variable "instance_type_worker" {
  description = "Type d'instance pour les workers."
  default     = "t3.medium"
}


variable "public_key_path" {
  description = "Chemin vers la clé publique SSH."
  default     = "~/.ssh/id_ed25519.pub"
}

variable "num_workers" {
  description = "Nombre de workers à déployer."
  default     = 2
}

variable "cluster_name" {
  description = "Nom unique pour le cluster Kubernetes"
  type        = string
}

variable "environment" {
  description = "Environnement d'exécution (e.g., dev, staging, prod)"
  type        = string
}

variable "owner" {
  description = "Propriétaire du cluster"
  type        = string
}

variable "project" {
  description = "Nom du projet"
  type        = string
}

variable "deployed_by" {
  description = "Nom de la personne qui déploie les ressources"
  type        = string
  
}