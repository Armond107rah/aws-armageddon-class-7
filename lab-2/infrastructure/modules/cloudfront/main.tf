
resource "aws_cloudfront_distribution" "app" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Lab 2 CloudFront distribution"
  price_class     = "PriceClass_100"

  aliases = [var.viewer_domain_name]

  origin {
    domain_name = var.origin_domain_name
    origin_id   = "lab2-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Origin-Verify"
      value = var.origin_verify_header
    }
  }

  default_cache_behavior {
    target_origin_id       = "lab2-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET", "HEAD", "OPTIONS",
      "PUT", "POST", "PATCH", "DELETE"
    ]

    cached_methods = ["GET", "HEAD"]

    # AWS-managed CachingDisabled policy
    cache_policy_id = aws_cloudfront_cache_policy.api_disabled.id

    # AWS-managed AllViewerExceptHostHeader policy
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "lab2-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = aws_cloudfront_cache_policy.static.id

    origin_request_policy_id = (
      aws_cloudfront_origin_request_policy.static.id
    )

    response_headers_policy_id = (
      aws_cloudfront_response_headers_policy.static.id
    )

    compress = true
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "lab2-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET", "HEAD", "OPTIONS",
      "PUT", "POST", "PATCH", "DELETE"
    ]

    cached_methods = ["GET", "HEAD"]

    cache_policy_id = aws_cloudfront_cache_policy.api_disabled.id

    origin_request_policy_id = (
      aws_cloudfront_origin_request_policy.api.id
    )

    compress = true
  }

  viewer_certificate {
    acm_certificate_arn      = var.viewer_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = var.web_acl_arn

  tags = {
    Name = "lab2-cloudfront"
  }
}