# outputs.tf

output "bastion_public_ip" {
  description = "Adresse IP publique du bastion."
  value       = module.bastion.bastion_public_ip
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
  value       =  module.vpc.private_subnet_ids
  
}

output "clusters_ips" {
  description = "Adresses IP pour tous les clusters Kubernetes"
  value = {
    bastion_public_ip = module.bastion.bastion_public_ip
    clusters = {
      for cluster_key, cluster in var.clusters : cluster_key => {
        controlplane_private_ip = module.controlplane[cluster_key].controlplane_private_ip
        workers_private_ips     = module.workers[cluster_key].workers_private_ips
      }
    }
  }
}
