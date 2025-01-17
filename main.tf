provider "aws" {
  region     = var.aws_region
}

locals {
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project
    Cluster     = var.cluster_name
    DeploymentDate = timestamp()
    DeployedBy     = var.deployed_by
  }
}

module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  aws_region          = var.aws_region
  cluster_name        = var.cluster_name
  environment         = var.environment
  owner               = var.owner
  deployed_by         = var.deployed_by
  project             = var.project
}

module "security_groups" {
  source                = "./modules/security_groups"
  cluster_name          = var.cluster_name
  vpc_id                = module.vpc.vpc_id
  bastion_ingress_cidr  = var.bastion_ingress_user_public_ip
  k8s_controlplane_sg_rules = var.k8s_controlplane_sg_rules
  k8s_worker_sg_rules        = var.k8s_worker_sg_rules
  environment         = var.environment
  owner               = var.owner
  deployed_by         = var.deployed_by
  project             = var.project
}

module "bastion" {
  source           = "./modules/bastion"
  cluster_name     = var.cluster_name
  ami              = var.bastion_ami
  instance_type    = var.instance_type_bastion
  subnet_id        = module.vpc.public_subnet_id
  key_pair_name    = aws_key_pair.deployer.key_name
  public_key_path     =  var.public_key_path	
  security_group_id = module.security_groups.bastion_sg_id
  environment         = var.environment
  owner               = var.owner
  deployed_by         = var.deployed_by
  project             = var.project
}

module "controlplane" {
  source              = "./modules/controlplane"
  cluster_name        = var.cluster_name
  ami                 = var.k8s_ami
  instance_type       = var.instance_type_controlplane
  subnet_id           = module.vpc.private_subnet_id
  key_pair_name       = aws_key_pair.deployer.key_name
  public_key_path     =  var.public_key_path	
  security_group_id   = module.security_groups.controlplane_sg_id
  num_workers = var.num_workers
  environment         = var.environment
  owner               = var.owner
  deployed_by         = var.deployed_by
  project             = var.project
}

module "workers" {
  source              = "./modules/workers"
  controlplane_private_ip = module.controlplane.controlplane_private_ip
  cluster_name        = var.cluster_name
  ami                 = var.k8s_ami
  instance_type       = var.instance_type_worker
  subnet_id           = module.vpc.private_subnet_id
  key_pair_name       = aws_key_pair.deployer.key_name
  public_key_path     =  var.public_key_path
  security_group_id   = module.security_groups.worker_sg_id
  environment         = var.environment
  owner               = var.owner
  deployed_by         = var.deployed_by
  project             = var.project
}