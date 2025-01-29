resource "local_file" "terraform_ssh_config" {
  for_each = var.clusters
  filename = pathexpand("~/.ssh/terraform/${each.value.name}_ssh_config")
  content = templatefile("${path.root}/templates/terraform_ssh_config.tpl", {
    bastion_public_ip       = module.bastion.bastion_public_ip
    controlplane_private_ip = module.controlplane[each.key].controlplane_private_ip
    workers_entries = join("\n\n", [
      for idx, ip in module.workers[each.key].workers_private_ips : <<-EOT
      Host worker${idx + 1}-${each.value.name} wk${idx + 1}-${each.value.name}
          HostName ${ip}
          User ubuntu
          StrictHostKeyChecking no
          UserKnownHostsFile /dev/null
          ProxyJump bastion
    EOT
    ])
    cluster_name = var.clusters[each.key].name
  })
}