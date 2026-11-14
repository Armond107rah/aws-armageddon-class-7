output "ec2_private_ip" {
  description = "Private EC2 IP address"
  value       = module.compute.private_ip
}
