# terraform-test/main.tf

provider "aws" {
  region     = var.aws_region
}

# Créer le VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "k8s-vpc"
  }
}

# Créer l'Internet Gateway
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "k8s-igw"
  }
}

# Créer le subnet public
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "k8s-public-subnet"
  }
}

# Créer le subnet privé
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "k8s-private-subnet"
  }
}

# Créer la Route Table pour le public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }

  tags = {
    Name = "k8s-public-rt"
  }
}

# Associer la Route Table au public subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Créer la NAT Gateway
resource "aws_eip" "nat_eip" {

}

resource "aws_nat_gateway" "k8s_natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "k8s-natgw"
  }
}

# Créer la Route Table pour les subnets privés
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.k8s_natgw.id
  }

  tags = {
    Name = "k8s-private-rt"
  }
}

# Associer la Route Table au private subnet
resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Groupe de sécurité pour le bastion
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for the bastion host"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_ingress_user_public_ip] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# Groupe de sécurité pour le control-plane
resource "aws_security_group" "controlplane_sg" {
  name        = "controlplane-sg"
  description = "Security group for the Kubernetes control-plane"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "Kubernetes API from bastion and workers"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
  }

    ingress {
    description = "Join the cluster"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
  }


  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "controlplane-sg"
  }
}

# Groupe de sécurité pour les workers
resource "aws_security_group" "worker_sg" {
  name        = "worker-sg"
  description = "Security group for the Kubernetes workers"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
  }

  ingress {
    description = "Kubernetes worker communication"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "worker-sg"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path) # Chemin vers votre clé publique SSH
}

# Clé SSH publique
data "template_file" "bastion_user_data" {
  template = file("scripts/bastion.sh")

  vars = {
    PUBLIC_KEY = file(var.public_key_path)
  }
}

# Clé SSH publique pour Kubernetes nodes
data "template_file" "k8s_master_user_data" {
  template = file("scripts/k8s-master.sh")

  vars = {
    PUBLIC_KEY = file(var.public_key_path)
    NUM_WORKERS= var.num_workers
  }
}

data "template_file" "k8s_worker_user_data" {
  template = file("scripts/k8s-worker.sh")

  vars = {
    PUBLIC_KEY = file(var.public_key_path)
    MASTER_IP  = aws_instance.controlplane.private_ip
  }
}

# Instance Bastion
resource "aws_instance" "bastion" {
  ami           = var.bastion_ami
  instance_type = var.instance_type_bastion
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = var.key_pair_name

  vpc_security_group_ids  = [
    aws_security_group.bastion_sg.id,
  ]

  associate_public_ip_address = true  # Assure l'attribution d'une IP publique


  user_data = data.template_file.bastion_user_data.rendered

  tags = {
    Name = "bastion"
  }
}

# Instance Control-plane
resource "aws_instance" "controlplane" {
  ami           = var.k8s_ami
  instance_type = var.instance_type_master
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    aws_security_group.controlplane_sg.id,
  ]

  user_data = data.template_file.k8s_master_user_data.rendered

  tags = {
    Name = "k8s-controlplane"
  }
}

# Instances Workers
resource "aws_instance" "workers" {
  count         = var.num_workers
  ami           = var.k8s_ami
  instance_type = var.instance_type_worker
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = var.key_pair_name

  vpc_security_group_ids = [
    aws_security_group.worker_sg.id,
  ]

  user_data = data.template_file.k8s_worker_user_data.rendered

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}

resource "local_file" "terraform_ssh_config" {
  filename = pathexpand("~/.ssh/terraform_ssh_config")  # Chemin correct pour Windows
  content  = templatefile("${path.root}/templates/terraform_ssh_config.tpl", {
    bastion_public_ip       = aws_instance.bastion.public_ip
    controlplane_private_ip = aws_instance.controlplane.private_ip
    workers_entries         = local.workers_entries
  })
}


locals {

  workers_entries = join("\n\n", [
    for idx, ip in aws_instance.workers[*].private_ip : <<-EOT
      Host aws-wk${idx + 1}
          HostName ${ip}
          User ubuntu
          StrictHostKeyChecking no
          UserKnownHostsFile /dev/null
          ProxyJump bastion
    EOT
  ])
}