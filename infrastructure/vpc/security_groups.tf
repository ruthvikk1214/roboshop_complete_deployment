# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${var.environment}-roboshop-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.roboshop.id

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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-alb-sg"
  })
}

# EKS Nodes Security Group
resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-roboshop-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.roboshop.id

  ingress {
    description = "Allow traffic from ALB"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  ingress {
    description = "Allow all traffic within VPC (pod-to-pod communication)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-eks-nodes-sg"
  })
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "${var.environment}-roboshop-database-sg"
  description = "Security group for databases"
  vpc_id      = aws_vpc.roboshop.id

  ingress {
    description = "Allow access from EKS nodes"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-database-sg"
  })
}
