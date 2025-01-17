output "workers_private_ips" {
  description = "Private IP addresses of the Kubernetes worker nodes"
  value       = aws_instance.workers[*].private_ip
}

output "worker_instance_ids" {
  description = "Instance IDs of the Kubernetes worker nodes"
  value       = aws_instance.workers[*].id
}