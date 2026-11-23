
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
