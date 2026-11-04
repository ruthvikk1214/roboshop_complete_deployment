output "eks_kms_key_arn" {
  description = "EKS KMS Key ARN"
  value       = aws_kms_key.eks.arn
}

output "s3_artifacts_kms_key_arn" {
  description = "S3 Artifacts KMS Key ARN"
  value       = aws_kms_key.s3_artifacts.arn
}

output "cloudwatch_kms_key_arn" {
  description = "CloudWatch KMS Key ARN"
  value       = aws_kms_key.cloudwatch.arn
}

output "ebs_kms_key_arn" {
  description = "EBS KMS Key ARN"
  value       = aws_kms_key.ebs.arn
}

output "artifacts_bucket_name" {
  description = "Artifacts S3 Bucket Name"
  value       = aws_s3_bucket.artifacts.bucket
}

output "terraform_state_bucket_name" {
  description = "Terraform State S3 Bucket Name"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_locks_table_name" {
  description = "Terraform Locks DynamoDB Table Name"
  value       = aws_dynamodb_table.terraform_locks.name
}