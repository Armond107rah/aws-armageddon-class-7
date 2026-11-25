
# Lesson 5 — Tokyo Private EC2 Application

## Business Problem
Prepare an application server that can securely
access the authoritative Tokyo database without
being directly exposed to the public internet.

## Implementation
- Defined private Amazon Linux 2023 EC2 configuration.
- Reused the existing Lab 2 Flask notes application.
- Configured the Tokyo application security group.
- Reused the application's IAM instance profile.
- Required IMDSv2.
- Configured encrypted EBS storage.
- Corrected AWS region and Parameter Store settings.
- Prepared Linux application startup automation.

## Security Decisions
- No public IP address.
- No SSH ingress.
- Database access restricted through security groups.
- IAM role instead of static AWS access keys.
- No passwords included in the bootstrap template.
- Deployment disabled until readiness checks pass.

## Outstanding Requirements
- VPC endpoints and private AWS service connectivity.
- Controlled application dependency installation.
- Verified TLS connection to RDS.
- Application monitoring and log sanitization.
- Approved load-balancer connectivity.
- End-to-end testing with synthetic records.

## Validation
Record the actual Terraform validation result here.

## Deployment Status
Not deployed. Configuration prepared for later testing.
