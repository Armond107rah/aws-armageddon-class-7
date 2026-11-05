
variable "allowed_http_cidr" {
  description = "Public IPv4 CIDR allowed to access the web server"
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_http_cidr, 0))
    error_message = "Enter a valid IPv4 CIDR, such as 203.0.113.25/32."
  }
}

variable "notification_email" {
  description = "Email address that receives AWS incident notifications"
  type        = string
}
