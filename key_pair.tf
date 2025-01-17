resource "aws_key_pair" "deployer" {
  key_name   = "${var.cluster_name}-key-pair"
  public_key = file(var.public_key_path) # Chemin vers votre clé publique SSH

  tags = merge(
    {
      Name = "${var.cluster_name}-key-pair"
    },
    local.common_tags
  )
}