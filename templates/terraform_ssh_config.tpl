# ~/.ssh/terraform_ssh_config

Host bastion
    HostName ${bastion_public_ip}
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519

Host aws-cp
    HostName ${controlplane_private_ip}
    User ubuntu
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no
    ProxyJump bastion

${workers_entries}