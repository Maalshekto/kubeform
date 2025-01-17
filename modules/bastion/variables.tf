variable "cluster_name" {
  description = "Unique name for the Kubernetes cluster"
  type        = string
}

variable "ami" {
  description = "AMI ID for the bastion host"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the bastion host"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the bastion host"
  type        = string
}

variable "key_pair_name" {
  description = "SSH key pair name"
  type        = string
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the bastion host"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
}

variable "owner" {
  description = "Owner of the cluster"
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