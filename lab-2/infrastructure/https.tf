locals {
  lab_domain     = "lab1c.epicreads.us"
  origin_domain  = "origin.lab1c.epicreads.us"
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
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}


resource "aws_acm_certificate" "lab2_origin" {
  domain_name       = local.origin_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "lab2-origin-certificate"
  }
}

resource "aws_route53_record" "lab2_origin_validation" {
  zone_id = local.hosted_zone_id

  name = one(
    aws_acm_certificate.lab2_origin.domain_validation_options
  ).resource_record_name

  type = one(
    aws_acm_certificate.lab2_origin.domain_validation_options
  ).resource_record_type

  records = [
    one(
      aws_acm_certificate.lab2_origin.domain_validation_options
    ).resource_record_value
  ]

  ttl = 60
}

resource "aws_acm_certificate_validation" "lab2_origin" {
  certificate_arn = aws_acm_certificate.lab2_origin.arn

  validation_record_fqdns = [
    aws_route53_record.lab2_origin_validation.fqdn
  ]
}


resource "aws_route53_record" "lab2_origin_alias" {
  zone_id = local.hosted_zone_id
  name    = local.origin_domain
  type    = "A"

  alias {
    name                   = module.load_balancer.alb_dns_name
    zone_id                = module.load_balancer.alb_zone_id
    evaluate_target_health = false
  }
}


resource "aws_route53_record" "lab1c_app_ipv6" {
  zone_id = local.hosted_zone_id
  name    = local.lab_domain
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
