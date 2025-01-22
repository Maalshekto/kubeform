variable "cluster_name" {
  description = "Unique name for the Kubernetes cluster"
  type        = string
}

variable "trigram" {
  description = "Unique name for the Kubernetes cluster"
  type        = string
  
}

variable "ami" {
  description = "AMI ID for the worker nodes"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the worker nodes"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the worker nodes"
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
  description = "Security group ID for the worker nodes"
  type        = string
}

variable "num_workers" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string    
}

variable "controlplane_private_ip" {
  description = "Private IP of the controlplane node"
  type        = string
}

variable "zsh_theme" {
  description = "Zsh theme"
  type        = string
}