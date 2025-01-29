variable "trigram" {
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

variable "clusters" {
  description = "Map des clusters (blue, green, etc.)"
  type = map(object({
    name                       = string
    private_subnet_cidr        = string
    ami                        = string
    instance_type_controlplane = string
    instance_type_worker       = string
    num_workers                = number
    k8s_version                = string
    zsh_theme                  = string
    cni                        = string
  }))
}

variable "controlplane_ips" {
  description = "Mapping cluster_key -> IP privée du controlplane"
  type        = map(string)
}

variable "weights" {
  description = "Mapping cluster_key -> weight for the load balancer"
  type        = map(number)
  default = {   
    blue = 100
    green = 0
  }
}