locals {
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project
    Cluster     = var.trigram
    DeploymentDate = timestamp()
    DeployedBy     = var.deployed_by
  }
}

# Instance Control-plane
resource "aws_instance" "controlplane" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = "${var.trigram}-key-pair"

  vpc_security_group_ids = [
    var.security_group_id,
  ]

  user_data = templatefile("${path.module}/templates/k8s-controlplane.sh.tpl", {
    hostname     = "controlplane"
    k8s_version  = var.k8s_version
    cluster_name = var.cluster_name
    PUBLIC_KEY = file(var.public_key_path)
    NUM_WORKERS= var.num_workers
  })

  tags = merge(
    {
      Name = "${var.trigram}-${var.cluster_name}-controlplane"
    },
    local.common_tags
  )
}
