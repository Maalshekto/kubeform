output "controlplane_private_ip" {
  description = "Private IP address of the Kubernetes control-plane"
  value       = aws_instance.controlplane.private_ip
}

output "controlplane_instance_id" {
  description = "Instance ID of the Kubernetes control-plane"
  value       = aws_instance.controlplane.id
}