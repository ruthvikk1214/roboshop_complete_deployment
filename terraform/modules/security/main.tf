# ALB Security Group (Public subnet - internet facing)
resource "aws_security_group" "alb" {
  name        = "${var.environment}-roboshop-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-alb-sg"
  })
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.environment}-roboshop-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id
  
  # Allow worker nodes to communicate with cluster
  ingress {
    description = "EKS worker node communication"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }
  
  # Allow kubectl access from bastion/VPN
  ingress {
    description = "Kubectl access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-eks-cluster-sg"
  })
}

# EKS Worker Nodes Security Group (Private subnet)
resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-roboshop-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id
  
  # Allow ALB to reach worker nodes (NodePort services)
  ingress {
    description = "ALB to worker nodes (NodePort range)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # Allow worker nodes to communicate with each other
  ingress {
    description = "Worker node to worker node"
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    self        = true
  }
  
  # Allow SSH from bastion/VPN
  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }
  
  # Allow access to databases
  egress {
    description = "To database security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.database.id]
  }
  
  # Allow outbound to internet via NAT
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-eks-nodes-sg"
  })
}

# Database Security Group (Database subnet)
resource "aws_security_group" "database" {
  name        = "${var.environment}-roboshop-database-sg"
  description = "Security group for managed databases"
  vpc_id      = var.vpc_id
  
  # DocumentDB/MongoDB
  ingress {
    description = "DocumentDB from EKS nodes"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }
  
  # MySQL/RDS
  ingress {
    description = "MySQL from EKS nodes"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }
  
  # Redis/ElastiCache
  ingress {
    description = "Redis from EKS nodes"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }
  
  # RabbitMQ/Amazon MQ
  ingress {
    description = "RabbitMQ AMQP from EKS nodes"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }
  
  ingress {
    description = "RabbitMQ Management from EKS nodes"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-database-sg"
  })
}

# VPC Endpoints Security Group
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.environment}-roboshop-vpc-endpoints-sg"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "HTTPS from EKS nodes"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-vpc-endpoints-sg"
  })
}