
output "tokyo_vpc_id" {
  description = "ID of the Tokyo VPC"
  value       = module.networking.vpc_id
}

output "tokyo_vpc_cidr" {
  description = "CIDR range of the Tokyo VPC"
  value       = module.networking.vpc_cidr_block
}

output "tokyo_public_subnet_ids" {
  description = "Public subnet IDs in Tokyo"
  value       = module.networking.public_subnet_ids
}

output "tokyo_private_subnet_ids" {
  description = "Private subnet IDs in Tokyo"
  value       = module.networking.private_subnet_ids
}

output "tokyo_private_route_table_id" {
  description = "Private route table ID in Tokyo"
  value       = module.networking.private_route_table_id
}

output "tokyo_region" {
  description = "Region of the Tokyo infrastructure"
  value       = var.aws_region
}

output "tokyo_app_security_group_id" {
  description = "Security group reserved for Tokyo application"
  value       = aws_security_group.tokyo_app.id
}

output "tokyo_ec2_instance_profile_name" {
  description = "Instance profile for future Tokyo EC2"
  value       = module.iam.instance_profile_name
}

output "tokyo_rds_endpoint" {
  description = "Private Tokyo RDS endpoint when enabled"

  value = (
    var.enable_tokyo_database
    ? module.database[0].rds_endpoint
    : null
  )

  sensitive = true
}

output "tokyo_rds_security_group_id" {
  description = "Tokyo database security group when enabled"

  value = (
    var.enable_tokyo_database
    ? module.database[0].rds_security_group_id
    : null
  )
}

output "tokyo_ec2_instance_id" {
  description = "Tokyo application instance ID when enabled"

  value = (
    var.enable_tokyo_compute
    ? aws_instance.tokyo_app[0].id
    : null
  )
}

output "tokyo_ec2_private_ip" {
  description = "Tokyo application private IP when enabled"

  value = (
    var.enable_tokyo_compute
    ? aws_instance.tokyo_app[0].private_ip
    : null
  )

  sensitive = true
}

output "tokyo_interface_endpoint_ids" {
  description = "Tokyo interface endpoint IDs by service"

  value = {
    for service, endpoint in aws_vpc_endpoint.tokyo_interface :
    service => endpoint.id
  }
}

output "tokyo_s3_gateway_endpoint_id" {
  description = "Tokyo S3 gateway endpoint ID when enabled"

  value = (
    var.enable_tokyo_private_endpoints
    ? aws_vpc_endpoint.tokyo_s3[0].id
    : null
  )
}
