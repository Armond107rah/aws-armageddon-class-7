variable "origin_domain_name" {
  description = "DNS hostname CloudFront uses to reach the ALB"
  type        = string
}

variable "viewer_domain_name" {
  description = "Public application hostname"
  type        = string
}

variable "viewer_certificate_arn" {
  description = "ACM certificate ARN for CloudFront"
  type        = string
}

variable "web_acl_arn" {
  description = "ARN of the CloudFront-scoped WAF Web ACL"
  type        = string
}

variable "origin_verify_header" {
  description = "Secret value CloudFront sends to the ALB"
  type        = string
  sensitive   = true
}