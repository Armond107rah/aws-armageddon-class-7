output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = aws_lb.app.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app.arn
}

output "target_group_arn" {
  description = "ARN of the application target group"
  value       = aws_lb_target_group.app.arn
}

output "security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID of the ALB"
  value       = aws_lb.app.zone_id
}

output "alb_arn_suffix" {
  description = "ALB identifier used for CloudWatch metrics"
  value       = aws_lb.app.arn_suffix
}