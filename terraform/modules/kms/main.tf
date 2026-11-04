# KMS Key for EKS Secrets Encryption
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "Allow administration of the key"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
      Action = [
        "kms:*"
      ]
      Resource = "*"
    }, {
      Sid    = "Allow EKS to use the key"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      Resource = "*"
    }]
  })
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-eks-kms"
  })
}

# KMS Key for S3 Artifact Bucket
resource "aws_kms_key" "s3_artifacts" {
  description             = "KMS key for S3 artifact bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-s3-artifacts-kms"
  })
}

# KMS Key for CloudWatch Logs
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-cloudwatch-kms"
  })
}

# KMS Key for EBS Volumes
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS volume encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-ebs-kms"
  })
}

# S3 Bucket for Deployment Artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.environment}-roboshop-artifacts-${data.aws_caller_identity.current.account_id}"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.s3_artifacts.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    enabled = true
    expiration {
      days = 90
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-artifacts"
  })
}

# S3 Bucket for Terraform State (if not using separate bucket)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.environment}-roboshop-terraform-state-${data.aws_caller_identity.current.account_id}"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-terraform-state"
  })
}

# DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.environment}-roboshop-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  ttl {
    attribute_name = "TTL"
    enabled        = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-terraform-locks"
  })
}

data "aws_caller_identity" "current" {}