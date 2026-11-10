# Create the public Application Load Balancer
module "load_balancer" {
  source = "./modules/load_balancer"

  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  ec2_security_group_id = module.compute.security_group_id
  certificate_arn       = aws_acm_certificate_validation.lab1c.certificate_arn
}

# Allow incoming HTTP only from the ALB
resource "aws_vpc_security_group_ingress_rule" "alb_to_private_ec2" {
  security_group_id = module.compute.security_group_id

  referenced_security_group_id = module.load_balancer.security_group_id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP from ALB to private EC2"
}

# Register private EC2 with the target group
resource "aws_lb_target_group_attachment" "private_ec2" {
  target_group_arn = module.load_balancer.target_group_arn
  target_id        = module.compute.instance_id
  port             = 80

  depends_on = [
    aws_vpc_security_group_ingress_rule.alb_to_private_ec2
  ]
}

# Return the public ALB hostname
output "alb_dns_name" {
  description = "Public URL hostname of the ALB"
  value       = module.load_balancer.alb_dns_name
}