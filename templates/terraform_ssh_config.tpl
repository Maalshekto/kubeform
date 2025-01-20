# ~/.ssh/terraform_ssh_config

Host bastion b
    HostName ${bastion_public_ip}
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519

Host controlplane-${cluster_name} cp-${cluster_name}
    HostName ${controlplane_private_ip}
    User ubuntu
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no
    ProxyJump bastion
    
${workers_entries}