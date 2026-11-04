output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.roboshop.arn
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.roboshop.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.roboshop.zone_id
}

output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = var.alb_sg_id
}

output "target_group_arns" {
  description = "Target Group ARNs"
  value = {
    frontend = aws_lb_target_group.frontend.arn
    catalogue = aws_lb_target_group.catalogue.arn
    user = aws_lb_target_group.user.arn
    cart = aws_lb_target_group.cart.arn
    shipping = aws_lb_target_group.shipping.arn
    payment = aws_lb_target_group.payment.arn
    dispatch = aws_lb_target_group.dispatch.arn
  }
}

output "https_listener_arn" {
  description = "HTTPS Listener ARN"
  value       = aws_lb_listener.https.arn
}