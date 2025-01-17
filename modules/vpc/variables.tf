variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
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