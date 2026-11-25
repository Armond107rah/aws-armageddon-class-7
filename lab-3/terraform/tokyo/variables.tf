
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

# Database deployment is intentionally disabled until the planned AWS deployment lesson.

variable "enable_tokyo_database" {
  description = "Enable the Tokyo RDS database and configuration"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Name of the synthetic lab database"
  type        = string
  default     = "labdb"
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  default     = "labadmin"
}

# Tokyo application deployment is disabled until the deployment readiness review.

variable "enable_tokyo_compute" {
  description = "Create the private Tokyo application EC2 instance"
  type        = bool
  default     = false
}

variable "tokyo_instance_type" {
  description = "EC2 instance type for the Tokyo application"
  type        = string
  default     = "t3.micro"
}

variable "tokyo_bootstrap_ready" {
  description = "Explicit confirmation that application deployment prerequisites are ready"
  type        = bool
  default     = false
}

# AWS interface endpoints remain disabled until the planned deployment lesson.

variable "enable_tokyo_private_endpoints" {
  description = "Deploy private Tokyo AWS service endpoints"
  type        = bool
  default     = false
}
