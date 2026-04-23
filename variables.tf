variable "aws_region" {
   description = "AWS Region for lab1c build"
   type        = string
   default     = "us-east-2"
}

variable "project_name" {
  description = "Used for tags and naming for Armageddon (kept as a variable so you can reuse this code for other labs/projects)."
  type        = string
  default     = "lab-1c"
}

variable "vpc_cidr" {
  description = "VPC CIDR (use 10.x.x.x/xx as instructed)
  type        = string
  default     = "lab1c"
}
variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}

variable "ssh_ingress_cidr" {
  description = "Temporary CIDR allowed to SSH to EC2 (set to YOUR_PUBLIC_IP/32)."
  type        = string
  default     = "203.0.113.10/32"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = ["10.234.0.0/24", "10.234.16.0", "10.234.32.0"]
}

variable "private_subnet_cidrs"{
  description = "Private subnet CIDRs (use 10.x.x.x/xx)."
  type        = list(string)
  default     = [10.234.128.0/24", "10.234.144.0/24", "10.234.160.0/24"]
}
variable "azs" {
  description = "Availability Zoneslist (match count with subnets)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}


variable "ec2_security_group_id" {
  description = "Optional security group ID for the app EC2 instance. If null, defaults to the EC2 security group created by this config."
  type        = string
  default     = null
}

variable "db_engine" {
  description = "RDS engine."
  type        = "mysql"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "lab1c"
}
variable "db_username" {
  description = "RDS master username (also written into Secrets Manager JSON)."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS master password (also written into Secrets Manager JSON)."
  type        = string
  sensitive   = true
  default     = "1234" # TODO: supply your own
}

variable "db_name" {
  description = "Application database name stored in SSM Parameter Store."
  type        = string
  default     = "labdb"
}

variable "secret_name" {
  description = "Secrets Manager secret name that stores DB credentials/config."
  type        = string
  default     = "terraform-secrets"
}

variable "ssm_param_prefix" {
  description = "Prefix for SSM parameters (endpoint/port/name will be created under this path)."
  type        = string
  default     = "/lab/db"
}

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "rahbrahfit@gmail.com"
}


variable "securestring_kms_key_id" {
  description = "Optional KMS key id/arn to encrypt SecureString SSM parameters. If null, parameters are stored as String."
  type        = string
  default     = null
}

variable "log_group_name" {
  description = "CloudWatch Logs log group name for the app."
  type        = string
  default     = "/lab-1c/app"
}

variable "log_retention_days" {
  description = "How long to retain application logs in CloudWatch Logs."
  type        = number
  default     = 7
}

variable "db_failure_filter_pattern" {
  description = "CloudWatch Logs filter pattern that identifies DB connection failures in your app logs."
  type        = string
  default     = "\"DB connection failed\""
}

variable "db_failure_metric_namespace" {
  description = "Namespace for the custom CloudWatch metric emitted by the log metric filter."
  type        = string
  default     = "Lab/App"
}

variable "db_failure_metric_name" {
  description = "Metric name for DB connection failures (emitted by the log metric filter)."
  type        = string
  default     = "DBConnectionFailures"
}

variable "alarm_email" {
  description = "Optional email address to subscribe to the SNS alerts topic."
  type        = string
  default     = null
}
