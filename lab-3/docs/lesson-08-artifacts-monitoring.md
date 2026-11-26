
# Lesson 8 — Private Application Artifacts and Monitoring

## Business Problem

Deploy a Tokyo application without exposing private
EC2 instances to the public internet.

## Implemented Configuration

- Private S3 artifact bucket configuration
- S3 public access blocked
- Server-side object encryption
- HTTPS-only S3 bucket policy
- Restricted EC2 IAM artifact permissions
- S3 gateway endpoint egress rule
- Local Python wheel packaging process
- Deployment artifact SHA256 verification
- CloudWatch application log group
- Restricted CloudWatch metric permissions
- EC2 bootstrap for offline Python installation

## Security Principles

- No credentials embedded in application artifacts
- Database certificate verification required
- Application artifacts checked for integrity
- No public EC2 IP or SSH access
- Application logs must exclude sensitive data
- Only synthetic test records permitted

## Validation Evidence

Python syntax: Record actual result
Artifact build: Record actual result
CA certificate loading: Record actual result
Terraform validate: Record actual result

## Deployment Blockers

- Test wheel compatibility in Amazon Linux
- Verify regional S3 endpoint and DNF access
- Verify AWS permissions and CloudWatch Agent startup
- Review API authentication before public exposure
- Verify RDS TLS end to end
- Confirm RDS version and instance availability
- Review cost estimate and cleanup procedure

## Status

Code prepared. No AWS infrastructure deployed.
