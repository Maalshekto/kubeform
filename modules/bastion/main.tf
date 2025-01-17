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

# Instance Bastion
resource "aws_instance" "bastion" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = "${var.cluster_name}-key-pair"

  vpc_security_group_ids  = [
    var.security_group_id
  ]

  associate_public_ip_address = true  # Assure l'attribution d'une IP publique


  user_data = templatefile("${path.module}/templates/bastion.sh.tpl", {
    PUBLIC_KEY = file(var.public_key_path)
    hostname = "bastion"
    cluster_name = var.cluster_name
  })

  tags = merge(
    {
      Name = "${var.cluster_name}-bastion"
    },
    local.common_tags
  )
}