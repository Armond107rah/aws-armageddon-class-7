
# AWS-maintained CloudFront origin-facing IP ranges
data "aws_ec2_managed_prefix_list" "cloudfront_origin" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Only CloudFront can reach the ALB on HTTPS
resource "aws_vpc_security_group_ingress_rule" "cloudfront_to_alb" {
  security_group_id = module.load_balancer.security_group_id

  prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront_origin.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "HTTPS access from CloudFront origin-facing IPs"
}

# Random secret shared between CloudFront and the ALB
resource "random_password" "origin_header" {
  length  = 32
  special = false
}
