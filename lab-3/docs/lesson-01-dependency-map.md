# Lab 3 — Terraform Dependency Map

## Business requirement
Create a cross-region medical application with
patient data stored only in Tokyo.

## Tokyo
- AWS Region: ap-northeast-1
- VPC and private subnets
- Application infrastructure
- Authoritative RDS MySQL
- Transit Gateway
- Security and audit logging

## Sao Paulo
- AWS Region: sa-east-1
- Separate VPC and private subnets
- Stateless application infrastructure
- Transit Gateway
- No patient-record database

## Existing Lab 2 modules to evaluate
- networking
- compute
- database
- iam
- load_balancer
- cloudfront
- monitoring
- parameters
- vpc_endpoints

## Missing Lab 3 components
- Regional Terraform state separation
- Transit Gateway peering
- Cross-region route tables
- Regional database access policies
- Global application routing design
- Audit evidence collection

## Security requirements
- No real patient data
- No secrets in Git
- No public database access
- Least-privilege IAM
- Sanitized logs and screenshots

## Deployment status
Not deployed. Architecture and code review only.