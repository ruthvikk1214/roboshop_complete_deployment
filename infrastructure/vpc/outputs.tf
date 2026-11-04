output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.roboshop.id
}

output "public_subnet_ids" {
  description = "List of Public Subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of Private Subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "List of Database Subnets"
  value       = aws_subnet.database[*].id
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "eks_nodes_sg_id" {
  value = aws_security_group.eks_nodes.id
}

output "database_sg_id" {
  value = aws_security_group.database.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.roboshop.cidr_block
}
