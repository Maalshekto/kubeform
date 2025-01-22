# Groupe de sécurité pour le bastion
resource "aws_security_group" "bastion_sg" {
  name        = "${var.trigram}-bastion-sg"
  description = "Security group for the bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_ingress_cidr] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.trigram}-bastion-sg"
  }
}

# Groupe de sécurité pour le control-plane
resource "aws_security_group" "controlplane_sg" {
  name        = "${var.trigram}-controlplane-sg"
  description = "Security group for the Kubernetes control-plane"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.k8s_controlplane_sg_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.trigram}-controlplane-sg"
  }
}

# Groupe de sécurité pour les workers
resource "aws_security_group" "worker_sg" {
  name        = "${var.trigram}-worker-sg"
  description = "Security group for the Kubernetes workers"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.k8s_worker_sg_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  tags = {
    Name = "${var.trigram}-worker-sg"
  }
}