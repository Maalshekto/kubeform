resource "local_file" "terraform_ssh_config" {
  filename = pathexpand("~/.ssh/terraform/terraform_ssh_config_${var.cluster_name}")  # Chemin correct pour Windows
  content  = templatefile("${path.root}/templates/terraform_ssh_config.tpl", {
    bastion_public_ip       = module.bastion.bastion_public_ip
    controlplane_private_ip = module.controlplane.controlplane_private_ip
    workers_entries         = local.workers_entries
    cluster_name            = var.cluster_name
  })
}


locals {

  workers_entries = join("\n\n", [
    for idx, ip in module.workers.workers_private_ips : <<-EOT
      Host worker${idx + 1}-${var.cluster_name} wk${idx + 1}-${var.cluster_name}
          HostName ${ip}
          User ubuntu
          StrictHostKeyChecking no
          UserKnownHostsFile /dev/null
          ProxyJump bastion-${var.cluster_name}
    EOT
  ])
}