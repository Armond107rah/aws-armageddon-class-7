
output "endpoint_parameter_name" {
  value = aws_ssm_parameter.db_endpoint.name
}

output "port_parameter_name" {
  value = aws_ssm_parameter.db_port.name
}

output "name_parameter_name" {
  value = aws_ssm_parameter.db_name.name
}

output "secret_arn_parameter_name" {
  value = aws_ssm_parameter.master_secret_arn.name
}

output "parameter_arns" {
  description = "Parameter ARNs for IAM access control"

  value = [
    aws_ssm_parameter.db_endpoint.arn,
    aws_ssm_parameter.db_port.arn,
    aws_ssm_parameter.db_name.arn,
    aws_ssm_parameter.master_secret_arn.arn
  ]
}
