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

# Public Subnets (for ALB, NAT Gateway)
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

# Private Subnets (for EKS worker nodes, microservices pods)
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

# Database Subnets (for RDS, DocumentDB, ElastiCache, MQ)
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

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-nat-eip-${count.index + 1}"
  })
}

# NAT Gateways (one per AZ for HA)
resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-nat-${count.index + 1}"
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

# Private Route Tables (one per AZ with corresponding NAT)
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.roboshop.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-private-rt-${count.index + 1}"
  })
}

# Database Route Table (no internet access)
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
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# DB Subnet Groups for RDS, DocumentDB, ElastiCache
resource "aws_db_subnet_group" "roboshop" {
  name       = "${var.environment}-roboshop-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-db-subnet-group"
  })
}

resource "aws_elasticache_subnet_group" "roboshop" {
  name       = "${var.environment}-roboshop-elasticache-subnet-group"
  subnet_ids = aws_subnet.database[*].id
}

# VPC Endpoints for private access to AWS services
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.roboshop.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private[*].id, aws_route_table.database.id]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.roboshop.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-ecr-api-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.roboshop.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-ecr-dkr-endpoint"
  })
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id            = aws_vpc.roboshop.id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-cloudwatch-logs-endpoint"
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.roboshop.id
  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-secretsmanager-endpoint"
  })
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.roboshop.id
  service_name      = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-kms-endpoint"
  })
}

# Data source for AZs
data "aws_availability_zones" "available" {
  state = "available"
}