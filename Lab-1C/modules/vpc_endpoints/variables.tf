
variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "endpoint_subnet_ids" {
  type = list(string)
}

variable "private_route_table_ids" {
  type = list(string)
}
