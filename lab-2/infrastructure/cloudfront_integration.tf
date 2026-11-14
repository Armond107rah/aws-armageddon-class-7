
module "cloudfront" {
  source = "./modules/cloudfront"

  # Public URL users visit
  viewer_domain_name = local.lab_domain

  # Origin hostname pointing to the ALB
  origin_domain_name = aws_route53_record.lab2_origin_alias.fqdn

  # Certificate used by CloudFront for viewers
  viewer_certificate_arn = (
    aws_acm_certificate_validation.lab1c.certificate_arn
  )

  # WAF attached to the CloudFront distribution
  web_acl_arn = aws_wafv2_web_acl.lab2_cloudfront.arn

  # Must match the secret enforced by the ALB
  origin_verify_header = random_password.origin_header.result

  # Ensure the ALB origin has a DNS record before CloudFront
  depends_on = [
    aws_route53_record.lab2_origin_alias
  ]
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain assigned by AWS"
  value       = module.cloudfront.distribution_domain_name
}
