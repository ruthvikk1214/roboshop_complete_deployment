variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "tags" {
  type    = map(string)
  default = {
    Project = "Roboshop"
  }
}

variable "allowed_ssh_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "roboshop" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "roboshop" {
  vpc_id = aws_vpc.roboshop.id

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.roboshop.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-public-${count.index + 1}"
    Type = "public"
    "kubernetes.io/role/elb" = "1"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.roboshop.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-private-${count.index + 1}"
    Type = "private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.roboshop.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-db-${count.index + 1}"
    Type = "database"
  })
}

# Elastic IP for NAT Gateway (Single NAT for cost saving)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-nat-eip"
  })
}

# NAT Gateway (Single NAT for cost saving)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-nat"
  })

  depends_on = [aws_internet_gateway.roboshop]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.roboshop.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.roboshop.id
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-public-rt"
  })
}

# Private Route Table (All private subnets use the single NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.roboshop.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-private-rt"
  })
}

# Database Route Table (No internet access)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.roboshop.id

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-db-rt"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}
