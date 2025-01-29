# Control-plane Instance 
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
    ZSH_THEME = var.zsh_theme
    CNI = var.cni
    jenkins_install = templatefile("${path.module}/templates/jenkins-install.sh.tpl", {})
  })

  tags = {
    Name = "${var.trigram}-${var.cluster_name}-controlplane"
  }
}
