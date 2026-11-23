
# Lab 3 — Multi-Region AWS Architecture

## Business Objective

Design an AWS healthcare application that supports
international access while keeping patient-record
storage within Tokyo, Japan.

## Tokyo Region

- AWS Region: ap-northeast-1
- VPC CIDR: 10.50.0.0/16
- Public Subnets: 10.50.1.0/24, 10.50.2.0/24
- Private Subnets: 10.50.11.0/24, 10.50.12.0/24
- Application infrastructure
- Private Amazon RDS MySQL database
- Regional Transit Gateway
- Monitoring and security logging

## São Paulo Region

- AWS Region: sa-east-1
- VPC CIDR: 10.60.0.0/16
- Public Subnets: 10.60.1.0/24, 10.60.2.0/24
- Private Subnets: 10.60.11.0/24, 10.60.12.0/24
- Stateless application infrastructure
- Regional Transit Gateway
- No patient-record database

## Cross-Region Connectivity

São Paulo application requests reach the Tokyo
database through regional Transit Gateways and a
cross-region peering attachment.

Both regions require explicit routing.

## Terraform State Management

- Tokyo and São Paulo use separate Terraform states.
- Each region manages its own infrastructure.
- Cross-region dependencies use explicit outputs.
- Secrets must not be committed to GitHub.

## Security Requirements

- No actual patient information.
- RDS must not be publicly accessible.
- Database access restricted to approved applications.
- TLS encryption for database connections.
- Least-privilege IAM permissions.
- CloudWatch and CloudTrail audit evidence.
- Sensitive information excluded from public evidence.

## Project Status

Architecture planning completed.
Infrastructure has not been deployed.
