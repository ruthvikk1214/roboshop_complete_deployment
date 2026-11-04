output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "eks_cluster_sg_id" {
  description = "EKS Cluster Security Group ID"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_sg_id" {
  description = "EKS Worker Nodes Security Group ID"
  value       = aws_security_group.eks_nodes.id
}

output "database_sg_id" {
  description = "Database Security Group ID"
  value       = aws_security_group.database.id
}

output "vpc_endpoints_sg_id" {
  description = "VPC Endpoints Security Group ID"
  value       = aws_security_group.vpc_endpoints.id
}