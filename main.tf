locals {
  # Extraire la liste des CIDR privés pour tous les clusters
  private_subnet_cidrs = [for cluster_key, cluster in var.clusters : cluster.private_subnet_cidr]

  # Créer une map de CIDR à subnet_id
  subnet_map = {
    for idx, cidr in module.vpc.private_subnet_cidrs :
    cidr => module.vpc.private_subnet_ids[idx]
  }
}

provider "aws" {
  region     = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Owner       = var.owner
      Project     = var.project
      Trigram     = var.trigram
      DeployedBy     = var.deployed_by
      Service        = var.service
    }
  } 
}

module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.bastion.public_subnet_cidr
  private_subnet_cidrs = [for cluster in var.clusters : cluster.private_subnet_cidr]
  aws_region          = var.aws_region
  cluster_names       = [for cluster in var.clusters : cluster.name]
  trigram            = var.trigram
}

module "security_groups" {
  source                = "./modules/security_groups"
  trigram               = var.trigram
  vpc_id                = module.vpc.vpc_id
  bastion_ingress_cidr  = var.bastion.ingress_user_public_ip
  k8s_controlplane_sg_rules = var.k8s_controlplane_sg_rules
  k8s_worker_sg_rules        = var.k8s_worker_sg_rules
}

module "bastion" {
  source           = "./modules/bastion"
  trigram          = var.trigram
  ami              = var.bastion.ami
  instance_type    = var.bastion.instance_type
  subnet_id        = module.vpc.public_subnet_id
  key_pair_name    = aws_key_pair.deployer.key_name
  public_key_path     =  var.public_key_path	
  security_group_id = module.security_groups.bastion_sg_id
}

module "controlplane" {
  for_each = var.clusters 
  source              = "./modules/controlplane"
  trigram             = var.trigram
  cluster_name        = each.value.name
  ami                 = each.value.ami
  k8s_version         = each.value.k8s_version
  instance_type       = each.value.instance_type_controlplane
  subnet_id           = local.subnet_map[each.value.private_subnet_cidr]
  key_pair_name       = aws_key_pair.deployer.key_name
  public_key_path     = var.public_key_path	
  security_group_id   = module.security_groups.controlplane_sg_id
  num_workers         = each.value.num_workers
  zsh_theme           = each.value.zsh_theme
}

module "workers" {
  for_each = var.clusters
  source              = "./modules/workers"
  trigram             = var.trigram
  controlplane_private_ip = module.controlplane[each.key].controlplane_private_ip
  cluster_name        = each.value.name
  ami                 = each.value.ami
  k8s_version         = each.value.k8s_version
  instance_type       = each.value.instance_type_worker
  subnet_id           = local.subnet_map[each.value.private_subnet_cidr]
  key_pair_name       = aws_key_pair.deployer.key_name
  public_key_path     =  var.public_key_path
  security_group_id   = module.security_groups.worker_sg_id
  zsh_theme           = each.value.zsh_theme
}