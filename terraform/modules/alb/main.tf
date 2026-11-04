# S3 Bucket for ALB Access Logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.environment}-roboshop-alb-logs-${var.aws_account_id}"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  lifecycle_rule {
    enabled = true
    expiration {
      days = 365
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-alb-logs"
  })
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AWSLogDeliveryWrite"
      Effect = "Allow"
      Principal = {
        Service = "delivery.logs.amazonaws.com"
      }
      Action = "s3:PutObject"
      Resource = "arn:aws:s3:::${aws_s3_bucket.alb_logs.bucket}/*"
      Condition = {
        StringEquals = {
          "s3:x-amz-acl" = "bucket-owner-full-control"
        }
      }
    }, {
      Sid    = "AWSLogDeliveryAclCheck"
      Effect = "Allow"
      Principal = {
        Service = "delivery.logs.amazonaws.com"
      }
      Action = "s3:GetBucketAcl"
      Resource = "arn:aws:s3:::${aws_s3_bucket.alb_logs.bucket}"
    }]
  })
}

# Application Load Balancer
resource "aws_lb" "roboshop" {
  name               = "${var.environment}-roboshop-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
  enable_deletion_protection = true
  enable_http2       = true
  enable_waf_fail_open = false
  ip_address_type    = "ipv4"
  
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "roboshop-alb"
    enabled = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-alb"
  })
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.roboshop.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener (requires ACM certificate)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.roboshop.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Target Group for Frontend (Nginx)
resource "aws_lb_target_group" "frontend" {
  name        = "${var.environment}-roboshop-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-frontend-tg"
  })
}

# Target Groups for Microservices (for ALB Ingress Controller)
resource "aws_lb_target_group" "catalogue" {
  name        = "${var.environment}-roboshop-catalogue-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-catalogue-tg"
  })
}

resource "aws_lb_target_group" "user" {
  name        = "${var.environment}-roboshop-user-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-user-tg"
  })
}

resource "aws_lb_target_group" "cart" {
  name        = "${var.environment}-roboshop-cart-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-cart-tg"
  })
}

resource "aws_lb_target_group" "shipping" {
  name        = "${var.environment}-roboshop-shipping-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-shipping-tg"
  })
}

resource "aws_lb_target_group" "payment" {
  name        = "${var.environment}-roboshop-payment-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-payment-tg"
  })
}

resource "aws_lb_target_group" "dispatch" {
  name        = "${var.environment}-roboshop-dispatch-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 60
    matcher             = "200"
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-dispatch-tg"
  })
}

# Listener Rules for path-based routing
resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/catalogue/*"]
    }
  }
}

resource "aws_lb_listener_rule" "user" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 110
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/user/*"]
    }
  }
}

resource "aws_lb_listener_rule" "cart" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 120
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cart.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/cart/*"]
    }
  }
}

resource "aws_lb_listener_rule" "shipping" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 130
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shipping.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/shipping/*"]
    }
  }
}

resource "aws_lb_listener_rule" "payment" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 140
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/payment/*"]
    }
  }
}

resource "aws_lb_listener_rule" "dispatch" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 150
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dispatch.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/dispatch/*"]
    }
  }
}

# Route53 Record
resource "aws_route53_record" "roboshop" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = aws_lb.roboshop.dns_name
    zone_id                = aws_lb.roboshop.zone_id
    evaluate_target_health = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-roboshop-dns"
  })
}

# Data source for Route53 Zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}