terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "roboshop"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "rk1214"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = aws_eks_cluster.roboshop.name
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = aws_eks_cluster.roboshop.name
  }
}