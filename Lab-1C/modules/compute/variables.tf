
variable "project_name" {
  description = "Name used for project resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC where EC2 will run"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet where EC2 will run"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile from IAM module"
  type        = string
}
