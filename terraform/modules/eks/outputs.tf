output "cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.roboshop.name
}

output "cluster_arn" {
  description = "EKS Cluster ARN"
  value       = aws_eks_cluster.roboshop.arn
}

output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = aws_eks_cluster.roboshop.endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS Cluster Certificate Authority Data"
  value       = aws_eks_cluster.roboshop.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "EKS Cluster OIDC Issuer URL"
  value       = aws_eks_cluster.roboshop.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "EKS Cluster OIDC Provider ARN"
  value       = aws_eks_cluster.roboshop.identity[0].oidc[0].provider_arn
}

output "node_group_name" {
  description = "EKS Node Group Name"
  value       = aws_eks_node_group.roboshop.node_group_name
}

output "node_group_arn" {
  description = "EKS Node Group ARN"
  value       = aws_eks_node_group.roboshop.arn
}

output "irsa_alb_controller_role_arn" {
  description = "IRSA ALB Controller Role ARN"
  value       = aws_iam_role.irsa_alb_controller.arn
}

output "irsa_external_dns_role_arn" {
  description = "IRSA External DNS Role ARN"
  value       = aws_iam_role.irsa_external_dns.arn
}

output "irsa_cluster_autoscaler_role_arn" {
  description = "IRSA Cluster Autoscaler Role ARN"
  value       = aws_iam_role.irsa_cluster_autoscaler.arn
}

output "irsa_ebs_csi_role_arn" {
  description = "IRSA EBS CSI Role ARN"
  value       = aws_iam_role.irsa_ebs_csi.arn
}

output "irsa_secrets_store_role_arn" {
  description = "IRSA Secrets Store Role ARN"
  value       = aws_iam_role.irsa_secrets_store.arn
}