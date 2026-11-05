
variable "project_name" {
  description = "Name used for project resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC where EC2 will run"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet for the temporary web server"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile from IAM module"
  type        = string
}

variable "allowed_http_cidr" {
  description = "Trusted IPv4 address range allowed to test the web server"
  type        = string
}
