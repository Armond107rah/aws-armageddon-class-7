locals {
  lab_domain     = "lab1c.epicreads.us"
  hosted_zone_id = "Z05665731WE3PNE3OBREF"
}

# Request a public SSL/TLS certificate
resource "aws_acm_certificate" "lab1c" {
  domain_name       = local.lab_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "lab1c-bonus-b-certificate"
  }
}

# Prove ownership of the domain using Route 53
resource "aws_route53_record" "lab1c_cert_validation" {
  zone_id = local.hosted_zone_id

  name    = one(aws_acm_certificate.lab1c.domain_validation_options).resource_record_name
  type    = one(aws_acm_certificate.lab1c.domain_validation_options).resource_record_type
  records = [one(aws_acm_certificate.lab1c.domain_validation_options).resource_record_value]

  ttl = 60
}

# Wait until ACM validates and issues the certificate
resource "aws_acm_certificate_validation" "lab1c" {
  certificate_arn = aws_acm_certificate.lab1c.arn

  validation_record_fqdns = [
    aws_route53_record.lab1c_cert_validation.fqdn
  ]
}

# Direct the lab subdomain to the ALB
resource "aws_route53_record" "lab1c_app" {
  zone_id = local.hosted_zone_id
  name    = local.lab_domain
  type    = "A"

  alias {
    name                   = module.load_balancer.alb_dns_name
    zone_id                = module.load_balancer.alb_zone_id
    evaluate_target_health = true
  }
}