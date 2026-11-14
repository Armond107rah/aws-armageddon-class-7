# Security group for the public ALB
resource "aws_security_group" "alb" {
  name_prefix = "lab1c-b-alb-"
  description = "Application Load Balancer security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "lab1c-bonus-b-alb-sg"
  }
}

# ALB can forward HTTP to private EC2 only
resource "aws_vpc_security_group_egress_rule" "to_ec2" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = var.ec2_security_group_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  description = "Allow ALB traffic to private EC2"
}

# Internet-facing Application Load Balancer
resource "aws_lb" "app" {
  name               = "lab1c-bonus-b-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]
  subnets         = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "lab1c-bonus-b-alb"
  }
}

# Target group for private EC2
resource "aws_lb_target_group" "app" {
  name        = "lab1c-bonus-b-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "lab1c-bonus-b-tg"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn

  port     = 443
  protocol = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.certificate_arn

  # Requests that do not match an allow rule are denied
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access denied"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "allow_cloudfront" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    http_header {
      http_header_name = "X-Origin-Verify"
      values           = [var.origin_verify_header]
    }
  }
}