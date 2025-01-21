# terraform-test/variables.tf

variable "aws_region" {
  description = "La région AWS où déployer les ressources."
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "CIDR pour le VPC."
  default     = "10.0.0.0/16"
}

variable "trigram" {
  description = "Trigram of the owner of the resources"
  type        = string
}

variable "bastion" {
  description = "Map des paramètres pour le bastion"
  type = object({
    name                 = string
    public_subnet_cidr   = string
    ami          = string
    ingress_user_public_ip = string
    instance_type = string
  })
  default = {
    name                 = "bastion"
    public_subnet_cidr   = "10.0.1.0/24"
    ami          = "ami-0e2d1158a7687ccde" # Remplacez par l'AMI appropriée pour votre région
    ingress_user_public_ip = "YOUR_PUBLIC_IP/32"
    instance_type = "t4g.small"
  }
}

variable "clusters" {
  description = "Map des clusters Kubernetes à créer"
  type = map(object({
    name                 = string
    private_subnet_cidr  = string
    ami                  = string
    instance_type_controlplane = string
    instance_type_worker = string
    num_workers     = number
    k8s_version     = string
  }))
  default = {
    cluster1 = {
      name                 = "blue"
      private_subnet_cidr  = "10.0.2.0/24"
      ami                  = "ami-0e2d1158a7687ccde" # Exemple d'AMI Ubuntu 20.04 LTS ARM64
      instance_type_controlplane = "t4g.medium"
      instance_type_worker = "t4g.medium"
      num_workers     = 2
      k8s_version = "1.31.5"
    },
    cluster2 = {
      name                 = "green"
      private_subnet_cidr  = "10.0.3.0/24"
      ami                  = "ami-0e2d1158a7687ccde"
      instance_type_controlplane = "t4g.medium"
      instance_type_worker = "t4g.medium"
      num_workers     = 2
      k8s_version = "1.32.1"
    }
  }
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

variable "public_key_path" {
  description = "Chemin vers la clé publique SSH."
  default     = "~/.ssh/id_ed25519.pub"
}

variable "project" {
  description = "Nom du projet"
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

variable "deployed_by" {
  description = "Nom de la personne qui déploie les ressources"
  type        = string
  
}