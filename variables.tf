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

variable "k8s_controlplane_sg_rules" {
  description = "Security group rules for the Kubernetes control-plane"
  type        = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Kubernetes API from bastion and workers"
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }, 
    {
      description = "Join the cluster"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "SSH from bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    }
    # Add more rules here if needed
  ]
}

variable "k8s_worker_sg_rules" {
  description = "Security group rules for the Kubernetes control-plane"
  type        = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
  {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
  },
  {
    description = "Kubernetes worker communication"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
  }
    # Add more rules here if needed
  ]
}

variable "k8s_ami" {
  description = "AMI pour les instances Kubernetes (Ubuntu 20.04)."
  default     = "ami-08b426ca1360eb488" # Remplacez par l'AMI appropriée pour votre région
}

variable "instance_type_bastion" {
  description = "Type d'instance pour le bastion."
  default     = "t3.small"
}

variable "instance_type_controlplane" {
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