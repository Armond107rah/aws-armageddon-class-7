variable "vpc_id" {
  description = "VPC where the ALB will operate"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs in different Availability Zones"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "The ALB requires at least two public subnets."
  }
}

variable "ec2_security_group_id" {
  description = "Security group of the private EC2 instance"
  type        = string
}

variable "certificate_arn" {
  description = "Validated ACM certificate ARN for HTTPS"
  type        = string
}