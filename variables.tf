# terraform-test/variables.tf

variable "aws_region" {
  description = "AWS region to deploy the resources."
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  default     = "10.0.0.0/16"
}

variable "trigram" {
  description = "Trigram of the owner of the resources"
  type        = string
}

variable "bastion" {
  description = "Parameters for the bastion host"
  type = object({
    name                   = string
    public_subnet_cidr     = string
    ami                    = string
    ingress_user_public_ip = string
    instance_type          = string
  })
  default = {
    name                   = "bastion"
    public_subnet_cidr     = "10.0.1.0/24"
    ami                    = "ami-0e2d1158a7687ccde" # Replace with your own AMI according to your region and architecture
    ingress_user_public_ip = "YOUR_PUBLIC_IP/32"
    instance_type          = "t4g.small" # Corresponding to ARM64 architecture - 2 vCPU, 2GB RAM - Check the pricing and adjust according to your needs
  }
}

variable "clusters" {
  description = "Parameters for the Kubernetes clusters"
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
  default = {
    cluster1 = {
      name                       = "blue"
      private_subnet_cidr        = "10.0.2.0/24"
      ami                        = "ami-0e2d1158a7687ccde" # Exemple d'AMI Ubuntu 20.04 LTS ARM64
      instance_type_controlplane = "t4g.medium"            # Corresponding to ARM64 architecture - 2 vCPU, 4GB RAM - Check the pricing and adjust according to your needs
      instance_type_worker       = "t4g.medium"
      num_workers                = 2        # Number of worker nodes
      k8s_version                = "1.31.5" # Kubernetes version
      zsh_theme                  = "fishy"  # Zsh theme
      cni                        = "calico" # CNI plugin to use
    },
    cluster2 = {
      name                       = "green"
      private_subnet_cidr        = "10.0.3.0/24"
      ami                        = "ami-0e2d1158a7687ccde"
      instance_type_controlplane = "t4g.medium"
      instance_type_worker       = "t4g.medium"
      num_workers                = 2
      k8s_version                = "1.32.1"
      zsh_theme                  = "fishy"
      cni                        = "calico"
    }
  }

  # TODO: Eventually, add more validation rules here
  validation {
    # TODO: support more CNI plugins
    condition = alltrue([
      for cluster in values(var.clusters) : contains(["calico", "cilium"], cluster.cni)
    ])
    error_message = "CNI must be either calico or cilium"
  }
}

variable "bastion_sg_rules" {
  description = "Security group rules for the Bastion host"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))
  default = [
    {
      description = "SSH from bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
    },
    {
      description = "http"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
    },
    {
      description = "traefik dashboard"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
    }
    # Add more rules here if needed
  ]
}

variable "k8s_controlplane_sg_rules" {
  description = "Security group rules for the Kubernetes control-plane"
  type = list(object({
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
      description = "Kubernetes worker communication - link Traefik to Nodeport services"
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "SSH from bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "DNS (UDP)"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "DNS (TCP)"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "DNS (TCP)"
      from_port   = 9153
      to_port     = 9153
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "BGP (TCP) - allow Calico communication"
      from_port   = 179
      to_port     = 179
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      protocol    = "4"             # IP-in-IP protocol
      from_port   = 0               # Not applicable for IP-in-IP, set to 0
      to_port     = 0               # Not applicable for IP-in-IP, set to 0
      cidr_blocks = ["10.0.0.0/16"] # Ajuste en fonction de ton VPC
      description = "IP-in-IP encapsulation for Calico"
    }
    # Add more rules here if needed
  ]
}

variable "k8s_worker_sg_rules" {
  description = "Security group rules for the Kubernetes control-plane"
  type = list(object({
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
      description = "BGP (TCP) - allow Calico communication"
      from_port   = 179
      to_port     = 179
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "kubectl exec from control-plane"
      from_port   = 10250
      to_port     = 10250
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      description = "Kubernetes worker communication"
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "DNS (UDP)"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "DNS (TCP)"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      description = "DNS (TCP)"
      from_port   = 9153
      to_port     = 9153
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    },
    {
      protocol    = "4"             # IP-in-IP protocol
      from_port   = 0               # Not applicable for IP-in-IP, set to 0
      to_port     = 0               # Not applicable for IP-in-IP, set to 0
      cidr_blocks = ["10.0.0.0/16"] # Ajuste en fonction de ton VPC
      description = "IP-in-IP encapsulation for Calico"
    },
    # Add more rules here if needed
  ]
}

variable "public_key_path" {
  description = "Chemin vers la clé publique SSH."
  default     = "~/.ssh/id_ed25519.pub"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. Dev, Prod)"
  type        = string
  default     = "Dev"
}

variable "owner" {
  description = "Cluster owner"
  type        = string
}

variable "deployed_by" {
  description = "Person who deployed the cluster"
  type        = string

}
variable "service" {
  description = "Concerned service"
  type        = string
  default     = "Devops"
}