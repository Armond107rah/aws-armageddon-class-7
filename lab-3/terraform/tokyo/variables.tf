
variable "aws_region" {
  description = "Primary AWS region for Lab 3"
  type        = string
  default     = "ap-northeast-1"

  validation {
    condition     = var.aws_region == "ap-northeast-1"
    error_message = "Tokyo infrastructure must use ap-northeast-1."
  }
}

variable "project_name" {
  description = "Prefix for Tokyo resources"
  type        = string
  default     = "shinjuku-lab3"
}

variable "vpc_cidr" {
  description = "Tokyo VPC network range"
  type        = string
  default     = "10.50.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two Tokyo public subnet ranges"
  type        = list(string)

  default = [
    "10.50.1.0/24",
    "10.50.2.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "Two Tokyo private subnet ranges"
  type        = list(string)

  default = [
    "10.50.11.0/24",
    "10.50.12.0/24"
  ]
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway"
  type        = bool
  default     = false
}
