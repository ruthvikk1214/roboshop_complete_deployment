# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "${var.environment}-roboshop-eks-cluster-role"
  
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

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# IAM Role for EKS Worker Nodes
resource "aws_iam_role" "eks_nodes" {
  name = "${var.environment}-roboshop-eks-nodes-role"
  
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

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_nodes.name
}

# Custom policy for secrets manager access
resource "aws_iam_policy" "eks_secrets" {
  name = "${var.environment}-roboshop-eks-secrets-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:roboshop/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_secrets_attachment" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = aws_iam_policy.eks_secrets.arn
}

# EKS Cluster
resource "aws_eks_cluster" "roboshop" {
  name     = "${var.environment}-roboshop-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version
  
  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [var.eks_cluster_sg_id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.allowed_ssh_cidr
  }
  
  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }
  
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-eks"
  })
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}

# EKS Node Group
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
  
  ami_type       = "AL2_x86_64"
  capacity_type  = "SPOT"
  disk_size      = 50
  
  labels = {
    Environment = var.environment
    Project     = "roboshop"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-eks-nodes"
  })
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly,
    aws_iam_role_policy_attachment.ssm_managed,
    aws_iam_role_policy_attachment.cloudwatch_agent,
    aws_iam_role_policy_attachment.eks_secrets_attachment,
  ]
}

# IAM Role for Kubernetes Service Accounts (IRSA)
resource "aws_iam_role" "irsa_alb_controller" {
  name = "${var.environment}-roboshop-alb-controller-irsa"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "alb_controller" {
  name = "${var.environment}-roboshop-alb-controller-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:CreateServiceLinkedRole",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAddresses",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeTags",
        "ec2:GetCoipPoolUsage",
        "ec2:DescribeCoipPools",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeListenerCertificates",
        "elasticloadbalancing:DescribeSSLPolicies",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:DescribeTags"
      ]
      Resource = "*"
    }, {
      Effect = "Allow"
      Action = [
        "cognito-idp:DescribeUserPoolClient",
        "acm:ListCertificates",
        "acm:DescribeCertificate",
        "iam:ListServerCertificates",
        "iam:GetServerCertificate",
        "waf-regional:GetWebACL",
        "waf-regional:GetWebACLForResource",
        "waf-regional:AssociateWebACL",
        "waf-regional:DisassociateWebACL",
        "wafv2:GetWebACL",
        "wafv2:GetWebACLForResource",
        "wafv2:AssociateWebACL",
        "wafv2:DisassociateWebACL",
        "shield:GetSubscriptionState",
        "shield:DescribeProtection",
        "shield:CreateProtection",
        "shield:DeleteProtection"
      ]
      Resource = "*"
    }, {
      Effect = "Allow"
      Action = [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress"
      ]
      Resource = "*"
    }, {
      Effect = "Allow"
      Action = [
        "ec2:CreateSecurityGroup"
      ]
      Resource = "*"
    }, {
      Effect = "Allow"
      Action = [
        "ec2:CreateTags"
      ]
      Resource = "arn:aws:ec2:*:*:security-group/*"
      Condition = {
        StringEquals = {
          "ec2:CreateAction" = "CreateSecurityGroup"
        }
        "Null" = {
          "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
    }, {
      Effect = "Allow"
      Action = [
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ]
      Resource = "arn:aws:ec2:*:*:security-group/*"
      Condition = {
        "Null" = {
          "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
    }, {
      Effect = "Allow"
      Action = [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DeleteSecurityGroup"
      ]
      Resource = "*"
      Condition = {
        "Null" = {
          "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
    }, {
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateTargetGroup"
      ]
      Resource = "*"
      Condition = {
        "Null" = {
          "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
    }, {
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule"
      ]
      Resource = "*"
    }, {
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ]
      Resource = [
        "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
      ]
      Condition = {
        "Null" = {
          "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
    }, {
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:DeleteTargetGroup"
      ]
      Resource = "*"
      Condition = {
        "Null" = {
          "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
    }, {
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ]
      Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
    }, {
      Effect = "Allow"
      Action = [
        "elasticloadbalancing:SetWebAcl",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:RemoveListenerCertificates",
        "elasticloadbalancing:ModifyRule"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attachment" {
  role       = aws_iam_role.irsa_alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# IRSA for External DNS
resource "aws_iam_role" "irsa_external_dns" {
  name = "${var.environment}-roboshop-external-dns-irsa"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:kube-system:external-dns"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "external_dns" {
  name = "${var.environment}-roboshop-external-dns-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets",
        "route53:ListHostedZones",
        "route53:ListHostedZonesByName"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_attachment" {
  role       = aws_iam_role.irsa_external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

# IRSA for Cluster Autoscaler
resource "aws_iam_role" "irsa_cluster_autoscaler" {
  name = "${var.environment}-roboshop-cluster-autoscaler-irsa"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${var.environment}-roboshop-cluster-autoscaler-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attachment" {
  role       = aws_iam_role.irsa_cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

# IRSA for EBS CSI Driver
resource "aws_iam_role" "irsa_ebs_csi" {
  name = "${var.environment}-roboshop-ebs-csi-irsa"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "ebs_csi" {
  name = "${var.environment}-roboshop-ebs-csi-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attachment" {
  role       = aws_iam_role.irsa_ebs_csi.name
  policy_arn = aws_iam_policy.ebs_csi.arn
}

# IRSA for Secrets Store CSI Driver
resource "aws_iam_role" "irsa_secrets_store" {
  name = "${var.environment}-roboshop-secrets-store-irsa"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${aws_eks_cluster.roboshop.identity[0].oidc[0].issuer}:sub" = "system:serviceaccount:kube-system:secrets-store-csi-driver"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "secrets_store" {
  name = "${var.environment}-roboshop-secrets-store-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:roboshop/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_store_attachment" {
  role       = aws_iam_role.irsa_secrets_store.name
  policy_arn = aws_iam_policy.secrets_store.arn
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}