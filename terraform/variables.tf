variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB, NAT Gateway)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (EKS worker nodes, microservices)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets (RDS, DocumentDB, ElastiCache, MQ)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "eks_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_group_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "domain_name" {
  description = "Base domain name for Route53"
  type        = string
  default     = "rk1214.in"
}

variable "subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "roboshop"
}

variable "mongodb_password" {
  description = "MongoDB/DocumentDB password"
  type        = string
  sensitive   = true
}

variable "mysql_password" {
  description = "MySQL/RDS password"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Redis/ElastiCache password"
  type        = string
  sensitive   = true
}

variable "rabbitmq_password" {
  description = "RabbitMQ/Amazon MQ password"
  type        = string
  sensitive   = true
}

variable "alert_email" {
  description = "Email for CloudWatch alerts"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}