variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "database_subnet_ids" {
  description = "Database subnet IDs"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "DB subnet group name"
  type        = string
}

variable "elasticache_subnet_group_name" {
  description = "ElastiCache subnet group name"
  type        = string
}

variable "database_sg_id" {
  description = "Database Security Group ID"
  type        = string
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

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}