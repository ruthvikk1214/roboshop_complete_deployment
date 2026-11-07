variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "domain_name" {
  description = "The base domain name (e.g., rk1214.in)"
  type        = string
  default     = "rk1214.in"
}

variable "subdomain" {
  description = "The subdomain for the app (e.g., roboshop)"
  type        = string
  default     = "roboshop"
}

variable "tags" {
  type = map(string)
  default = {
    Project = "Roboshop"
  }
}

# Data source to find the existing Hosted Zone for the domain
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# The Route53 record for the application
# Note: This is commented out because the ALB is created by the AWS LB Controller in K8s.
# It is recommended to use ExternalDNS for automatic record management.

resource "aws_route53_record" "roboshop" {
  count   = var.alb_dns_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}


variable "alb_dns_name" {
  description = "The DNS name of the ALB"
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "The Zone ID of the ALB"
  type        = string
  default     = ""
}

output "app_url" {
  value = "https://${var.subdomain}.${var.domain_name}"
}
