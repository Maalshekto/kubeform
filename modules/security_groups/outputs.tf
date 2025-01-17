output "bastion_sg_id" {
  description = "Security group ID for the bastion host"
  value       = aws_security_group.bastion_sg.id
}

output "controlplane_sg_id" {
  description = "Security group ID for the Kubernetes control-plane"
  value       = aws_security_group.controlplane_sg.id
}

output "worker_sg_id" {
  description = "Security group ID for the Kubernetes workers"
  value       = aws_security_group.worker_sg.id
}