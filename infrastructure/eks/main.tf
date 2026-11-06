# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  # name removed to avoid EntityAlreadyExists errors in CI/CD

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "eks_nodes" {
  # name removed to avoid EntityAlreadyExists errors in CI/CD

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# EKS Cluster
resource "aws_eks_cluster" "roboshop" {
  name     = "${var.environment}-roboshop-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.31"

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [var.eks_cluster_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# EKS Node Group (Spot Instances for cost saving)
resource "aws_eks_node_group" "roboshop" {
  cluster_name    = aws_eks_cluster.roboshop.name
  node_group_name = "${var.environment}-roboshop-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  instance_types = var.node_group_instance_types
  capacity_type  = "SPOT"
  ami_type       = "AL2_x86_64"

  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-eks-nodes"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly,
  ]
}

# For Route53 integration: we assume an ALB will be created via Helm/Kubernetes
# We provide the placeholder outputs for the root module to link to Route53
# Note: In a real scenario, the ALB is created by the AWS Load Balancer Controller
# inside K8s, so the DNS name isn't available until AFTER the cluster is up.

output "cluster_endpoint" {
  value = aws_eks_cluster.roboshop.endpoint
}
