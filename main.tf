provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Owner       = var.owner
      Project     = var.project
      Trigram     = var.trigram
      DeployedBy  = var.deployed_by
      Service     = var.service
    }
  }
}

locals {
  # Get the private IP of the controlplane instances
  private_subnet_cidrs = [for cluster_key, cluster in var.clusters : cluster.private_subnet_cidr]

  # Create a map of private subnet CIDR -> subnet ID
  subnet_map = {
    for idx, cidr in module.vpc.private_subnet_cidrs :
    cidr => module.vpc.private_subnet_ids[idx]
  }

  # Create a map of cluster name -> controlplane private IP address to pass to the bastion for traefik configuration 
  controlplane_private_ips = {
    for k, cp_mod in module.controlplane :
    k => cp_mod.controlplane_private_ip
  }
}

# VPC module - creates the VPC, public and private subnets, route tables, and internet gateway etc.
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.bastion.public_subnet_cidr
  private_subnet_cidrs = [for cluster in var.clusters : cluster.private_subnet_cidr]
  aws_region           = var.aws_region
  cluster_names        = [for cluster in var.clusters : cluster.name]
  trigram              = var.trigram
}

# Security Groups module - creates the security groups for the bastion, controlplane, and workers
module "security_groups" {
  source                    = "./modules/security_groups"
  trigram                   = var.trigram
  vpc_id                    = module.vpc.vpc_id
  bastion_ingress_cidr      = var.bastion.ingress_user_public_ip
  bastion_sg_rules          = var.bastion_sg_rules
  k8s_controlplane_sg_rules = var.k8s_controlplane_sg_rules
  k8s_worker_sg_rules       = var.k8s_worker_sg_rules
}

# Bastion module - creates the bastion host
module "bastion" {
  source            = "./modules/bastion"
  trigram           = var.trigram
  ami               = var.bastion.ami
  instance_type     = var.bastion.instance_type
  subnet_id         = module.vpc.public_subnet_id
  key_pair_name     = aws_key_pair.deployer.key_name
  public_key_path   = var.public_key_path
  security_group_id = module.security_groups.bastion_sg_id
  clusters          = var.clusters
  controlplane_ips  = local.controlplane_private_ips
}

# Controlplane module - creates the controlplane instances
module "controlplane" {
  for_each          = var.clusters
  source            = "./modules/controlplane"
  trigram           = var.trigram
  cluster_name      = each.value.name
  ami               = each.value.ami
  k8s_version       = each.value.k8s_version
  instance_type     = each.value.instance_type_controlplane
  subnet_id         = local.subnet_map[each.value.private_subnet_cidr]
  key_pair_name     = aws_key_pair.deployer.key_name
  public_key_path   = var.public_key_path
  security_group_id = module.security_groups.controlplane_sg_id
  num_workers       = each.value.num_workers
  zsh_theme         = each.value.zsh_theme
  cni               = each.value.cni
}

# Workers module - creates the worker instances
module "workers" {
  for_each                = var.clusters
  source                  = "./modules/workers"
  trigram                 = var.trigram
  controlplane_private_ip = module.controlplane[each.key].controlplane_private_ip
  cluster_name            = each.value.name
  ami                     = each.value.ami
  k8s_version             = each.value.k8s_version
  instance_type           = each.value.instance_type_worker
  subnet_id               = local.subnet_map[each.value.private_subnet_cidr]
  key_pair_name           = aws_key_pair.deployer.key_name
  public_key_path         = var.public_key_path
  security_group_id       = module.security_groups.worker_sg_id
  zsh_theme               = each.value.zsh_theme
}