output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.app.id
}

output "distribution_domain_name" {
  description = "CloudFront distribution DNS hostname"
  value       = aws_cloudfront_distribution.app.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront hosted zone ID for Route 53"
  value       = aws_cloudfront_distribution.app.hosted_zone_id
}