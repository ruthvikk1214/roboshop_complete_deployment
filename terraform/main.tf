# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  database_subnet_cidrs  = var.database_subnet_cidrs
  aws_region             = var.aws_region
  environment            = var.environment
  tags                   = var.tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  vpc_id            = module.networking.vpc_id
  environment       = var.environment
  allowed_ssh_cidr  = var.allowed_ssh_cidr
  tags              = var.tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  environment                  = var.environment
  aws_region                   = var.aws_region
  aws_account_id               = data.aws_caller_identity.current.account_id
  eks_version                  = var.eks_version
  private_subnet_ids           = module.networking.private_subnet_ids
  eks_cluster_sg_id            = module.security.eks_cluster_sg_id
  node_group_instance_types    = var.node_group_instance_types
  node_group_desired_size      = var.node_group_desired_size
  node_group_min_size          = var.node_group_min_size
  node_group_max_size          = var.node_group_max_size
  kms_key_arn                  = module.kms.eks_kms_key_arn
  allowed_ssh_cidr             = var.allowed_ssh_cidr
  tags                         = var.tags
}

# KMS Module (for EKS encryption and other services)
module "kms" {
  source = "./modules/kms"
  
  environment = var.environment
  tags        = var.tags
}

# Databases Module
module "databases" {
  source = "./modules/databases"
  
  environment                   = var.environment
  aws_region                    = var.aws_region
  database_subnet_ids           = module.networking.database_subnet_ids
  db_subnet_group_name          = module.networking.db_subnet_group_name
  elasticache_subnet_group_name = module.networking.elasticache_subnet_group_name
  database_sg_id                = module.security.database_sg_id
  mongodb_password              = var.mongodb_password
  mysql_password                = var.mysql_password
  redis_password                = var.redis_password
  rabbitmq_password             = var.rabbitmq_password
  tags                          = var.tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"
  
  environment            = var.environment
  aws_region             = var.aws_region
  aws_account_id         = data.aws_caller_identity.current.account_id
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  alb_sg_id              = module.security.alb_sg_id
  domain_name            = var.domain_name
  subdomain              = var.subdomain
  acm_certificate_arn    = var.acm_certificate_arn
  tags                   = var.tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  environment       = var.environment
  aws_region        = var.aws_region
  alert_email       = var.alert_email
  alb_arn           = module.alb.alb_arn
  cluster_name      = module.eks.cluster_name
  tags              = var.tags
}