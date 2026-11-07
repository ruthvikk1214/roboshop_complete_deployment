terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "roboshop-terraform-state-rk1214"
    key     = "roboshop/infrastructure.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./vpc"

  aws_region            = var.aws_region
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  tags                  = var.tags
}

# Route53 Module
module "route53" {
  source = "./route53"

  aws_region  = var.aws_region
  domain_name = var.domain_name
  subdomain   = var.subdomain
  tags        = var.tags

  alb_dns_name = var.alb_dns_name
  alb_zone_id  = var.alb_zone_id
}

# EKS Module
module "eks" {
  source = "./eks"

  aws_region                = var.aws_region
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids         = module.vpc.public_subnet_ids
  eks_cluster_sg_id         = module.vpc.eks_nodes_sg_id
  node_group_instance_types = var.node_group_instance_types
  node_group_desired_size   = var.node_group_desired_size
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size
  tags                      = var.tags
}
