# Bastion Instance
resource "aws_instance" "bastion" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = "${var.trigram}-key-pair"

  vpc_security_group_ids  = [
    var.security_group_id
  ]

  associate_public_ip_address = true  # Assure that the bastion has a public IP


  user_data = templatefile("${path.module}/templates/bastion.sh.tpl", {
    PUBLIC_KEY = file(var.public_key_path)
    hostname = "bastion"
    trigram = var.trigram
    dynamic_conf  = templatefile("${path.module}/templates/dynamic_conf.toml.tpl", {
      controlplane_ips = var.controlplane_ips
      clusters = var.clusters
      # weights for the load balancer according to the cluster name
      weights = var.weights
    })
    traefik_conf  = templatefile("${path.module}/templates/traefik.toml.tpl", {})
  })
  tags = {
    Name = "${var.trigram}-bastion"
  }
}