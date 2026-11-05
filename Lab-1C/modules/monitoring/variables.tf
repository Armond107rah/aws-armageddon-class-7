
variable "project_name" {
  description = "Project identifier used for resource names"
  type        = string
}

variable "db_instance_identifier" {
  description = "RDS database instance identifier"
  type        = string
}

variable "notification_email" {
  description = "Email address for incident notifications"
  type        = string
}

