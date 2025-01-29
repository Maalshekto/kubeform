# Workers Instances
resource "aws_instance" "workers" {
  count         = var.num_workers
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = "${var.trigram}-key-pair"

  vpc_security_group_ids = [
    var.security_group_id,
  ]

  user_data = templatefile("${path.module}/templates/k8s-worker.sh.tpl", {
    k8s_version = var.k8s_version
    hostname     = "worker${count.index + 1}"
    cluster_name = var.cluster_name
    PUBLIC_KEY = file(var.public_key_path)
    CONTROLPLANE_IP  = var.controlplane_private_ip
    ZSH_THEME = var.zsh_theme
  })
  tags = {
    Name = "${var.trigram}-${var.cluster_name}-worker-${count.index + 1}"
  }
}