variable "trigram" {
  description = "Trigram for the Kubernetes cluster"
  type        = string
}

variable "cluster_name" {
  description = "Unique name for the Kubernetes cluster"
  type        = string  
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string    
}

variable "ami" {
  description = "AMI ID for the controlplane host"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the controlplane host"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the controlplane host"
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
  description = "Security group ID for the controlplane host"
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
  description = "Project name"
  type        = string
}

variable "deployed_by" {
  description = "Name of the person deploying the resources"
  type        = string
  
}

variable "num_workers" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}