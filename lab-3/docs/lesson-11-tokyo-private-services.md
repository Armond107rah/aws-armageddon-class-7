
# Lesson 11 — Tokyo RDS and Private AWS Services

## Objective
Deploy Tokyo's authoritative database and private
service connectivity without exposing EC2 or RDS
to the public internet.

## Infrastructure
- RDS MySQL 8.4, Single-AZ
- Private subnets and restricted database SG
- RDS-managed database credentials
- TLS requirement through parameter group
- Five interface VPC endpoints
- One S3 gateway endpoint
- Private S3 artifact bucket
- CloudWatch application log group

## Verification Results
- Terraform apply: Pending
- RDS available: Pending
- RDS encryption: Pending
- RDS public access disabled: Pending
- TLS parameter enabled: Pending
- Secrets Manager status: Pending
- VPC endpoints available: Pending
- S3 protections: Pending
- CloudWatch retention: Pending

## Security Value
Database storage remains in Tokyo under the
lab's regional residency requirement.

The configuration prepares private access to
AWS services without requiring a NAT Gateway.

## Cost Controls
Document the deployment time, expected cost,
running resources, and planned cleanup.

## Next
Deploy the Tokyo Flask application and test
verified TLS connectivity using synthetic data.
