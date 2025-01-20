variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR block for the private subnet"
  type        = list(string)
}

variable "cluster_names" {
  description = "Names of the clusters"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "trigram" {
  description = "The trigram of the owner of the resources"
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