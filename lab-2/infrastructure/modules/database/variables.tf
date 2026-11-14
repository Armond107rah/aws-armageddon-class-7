
variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ec2_security_group_id" {
  type = string
}

variable "db_name" {
  type    = string
  default = "labdb"
}

variable "db_username" {
  type    = string
  default = "labadmin"
}
