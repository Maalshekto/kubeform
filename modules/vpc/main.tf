locals {
  common_tags = {
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project
    Trigram     = var.trigram
    DeploymentDate = timestamp()
    DeployedBy     = var.deployed_by
  }
}

# Créer le VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = merge(
    {
      Name = "${var.trigram}-vpc"
    },
    local.common_tags
  )
}

# Créer l'Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.trigram}-igw"
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
      Name = "${var.trigram}-public-subnet"
    },
    local.common_tags
  )
}

# Créer le subnet privé
resource "aws_subnet" "private" {
  count      = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}a"

  tags = merge (
    {
      Name = "${var.trigram}-${var.cluster_names[count.index]}-private-subnet"
    },
    local.common_tags
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = merge(
    {
      Name = "${var.trigram}-nat-gw"
    },
    local.common_tags
  )
}

# Créer la NAT Gateway
resource "aws_eip" "nat" {
  tags =  merge(
    {
      Name = "${var.trigram}-nat-eip"
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
      Name = "${var.trigram}-public-rt"
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
      Name = "${var.trigram}-private-rt"
    },
    local.common_tags
  )
}

# Associer la Route Table au private subnet
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
