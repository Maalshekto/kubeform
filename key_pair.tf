locals {
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project
    Trigram     = var.trigram
    DeploymentDate = timestamp()
    DeployedBy     = var.deployed_by
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.trigram}-key-pair"
  public_key = file(var.public_key_path) # Chemin vers votre clé publique SSH

  tags = merge(
    {
      Name = "${var.trigram}-key-pair"
    },
    local.common_tags
  )
}