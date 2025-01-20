output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR des sous-réseaux privés"
  value       = var.private_subnet_cidrs
}