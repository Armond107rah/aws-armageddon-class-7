variable "project_name" {
  description = "Name used to identify AWS resources"
  type        = string
}

variable "vpc_cidr" {
  description = "IP address range for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR ranges for two public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR ranges for two private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Controls whether a NAT gateway is created"
  type        = bool
  default     = false
}
