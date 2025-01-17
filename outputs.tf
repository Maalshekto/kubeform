# outputs.tf

output "bastion_public_ip" {
  description = "Adresse IP publique du bastion."
  value       = module.bastion.bastion_public_ip
}

output "controlplane_private_ip" {
  description = "Adresse IP privée du control-plane."
  value       = module.controlplane.controlplane_private_ip
}

output "worker_private_ips" {
  description = "Adresses IP privées des workers."
  value       = module.workers.workers_private_ips
}

output "vpc_id" {
  description = "ID du VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID du subnet public."
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID du subnet privé."
  value       = module.vpc.private_subnet_id
}
