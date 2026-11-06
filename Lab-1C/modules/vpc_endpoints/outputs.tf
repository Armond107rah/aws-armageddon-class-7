output "interface_endpoint_ids" {
  description = "IDs of interface VPC endpoints"

  value = {
    for name, endpoint in aws_vpc_endpoint.interface :
    name => endpoint.id
  }
}

output "s3_endpoint_id" {
  description = "S3 gateway endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "endpoint_security_group_id" {
  value = aws_security_group.endpoints.id
}
