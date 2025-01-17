locals {
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project
    Cluster     = var.cluster_name
    DeploymentDate = timestamp()
    DeployedBy     = var.deployed_by
  }
}

# Créer le VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = merge(
    {
      Name = "${var.cluster_name}-vpc"
    },
    local.common_tags
  )
}

# Créer l'Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.cluster_name}-igw"
    },
    local.common_tags
  )
}

# Créer le subnet public
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = merge (
    {
      Name = "${var.cluster_name}-public-subnet"
    },
    local.common_tags
  )
}

# Créer le subnet privé
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = merge (
    {
      Name = "${var.cluster_name}-private-subnet"
    },
    local.common_tags
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = merge(
    {
      Name = "${var.cluster_name}-nat-gw"
    },
    local.common_tags
  )
}

# Créer la NAT Gateway
resource "aws_eip" "nat" {
  tags =  merge(
    {
      Name = "${var.cluster_name}-nat-eip"
    },   
    local.common_tags
  )
}

# Créer la Route Table pour le public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name = "${var.cluster_name}-public-rt"
    },  
    local.common_tags
  )
}

# Associer la Route Table au public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Créer la Route Table pour les subnets privés
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(
    {
      Name = "${var.cluster_name}-private-rt"
    },
    local.common_tags
  )
}

# Associer la Route Table au private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
