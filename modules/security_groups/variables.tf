variable "cluster_name" {
  description = "Unique name for the Kubernetes cluster"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "bastion_ingress_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
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
}

variable "k8s_worker_sg_rules" {
  description = "Security group rules for the Kubernetes workers"
  type        = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
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