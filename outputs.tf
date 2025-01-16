# outputs.tf

output "bastion_public_ip" {
  description = "Adresse IP publique du bastion."
  value       = aws_instance.bastion.public_ip
}

output "controlplane_private_ip" {
  description = "Adresse IP privée du control-plane."
  value       = aws_instance.controlplane.private_ip
}

output "worker_private_ips" {
  description = "Adresses IP privées des workers."
  value       = aws_instance.workers.*.private_ip
}

output "vpc_id" {
  description = "ID du VPC."
  value       = aws_vpc.k8s_vpc.id
}

output "public_subnet_id" {
  description = "ID du subnet public."
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "ID du subnet privé."
  value       = aws_subnet.private_subnet.id
}
