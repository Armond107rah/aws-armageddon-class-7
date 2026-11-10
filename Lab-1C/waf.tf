resource "aws_wafv2_web_acl" "lab1c" {
  name        = "lab1c-bonus-b-waf"
  description = "Web protection for the Lab 1C ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS managed security rules
  rule {
    name     = "AWSCommonProtection"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "lab1c-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # Rate-limit excessive traffic from one IP
  rule {
    name     = "RateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "lab1c-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "lab1c-bonus-b-waf"
    sampled_requests_enabled   = true
  }
}

# Associate WAF with our Application Load Balancer
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = module.load_balancer.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.lab1c.arn
}