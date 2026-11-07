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
  default = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "database_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.21.0/24", "10.1.22.0/24"]
}

variable "domain_name" {
  type    = string
  default = "rk1214.in"
}

variable "subdomain" {
  type    = string
  default = "roboshop"
}

variable "node_group_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_group_desired_size" {
  type    = number
  default = 2
}

variable "node_group_min_size" {
  type    = number
  default = 1
}

variable "node_group_max_size" {
  type    = number
  default = 3
}

variable "alb_dns_name" {
  description = "The DNS name of the ALB (populated after K8s ALB Controller creates the ALB)"
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "The Zone ID of the ALB (populated after K8s ALB Controller creates the ALB)"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {
    Project = "Roboshop"
  }
}
