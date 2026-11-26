
# ==========================================
# DATABASE MODULE VARIABLES
# ==========================================

variable "project_name" {
  description = "Name prefix for database resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC hosting the Tokyo database"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "Approved application security group"
  type        = string
}

variable "db_name" {
  description = "Application database name"
  type        = string
  default     = "labdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "labadmin"
}
