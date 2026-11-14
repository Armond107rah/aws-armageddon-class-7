
variable "project_name" {
  description = "Name used to organize parameters"
  type        = string
}

variable "db_endpoint" {
  description = "RDS database hostname"
  type        = string
}

variable "db_port" {
  description = "RDS database port"
  type        = number
}

variable "db_name" {
  description = "Application database name"
  type        = string
}

variable "master_secret_arn" {
  description = "ARN of the RDS-managed secret"
  type        = string
}

variable "parameter_path" {
  description = "Base path for database configuration"
  type        = string
  default     = "/lab/db"
}
