
# Lesson 9 — Tokyo Deployment Readiness Review

## Project Objective

Validate Tokyo infrastructure before the first
controlled AWS deployment.

All application records must be synthetic.
Tokyo remains the authoritative database region.

## 1. Local Validation

- Terraform formatting: Pending
- Terraform validation: Pending
- Python syntax: Pending
- Application artifact build: Pending
- Application artifact integrity: Pending
- RDS CA trust bundle: Pending
- Amazon Linux wheel installation: Pending

Replace Pending only with actual test results.

## 2. AWS Compatibility

AWS Region: ap-northeast-1

Database:
- Engine: MySQL 8.4
- Instance class: db.t3.micro
- Storage: 20 GiB gp2
- Encrypted: Yes
- Public access: Disabled

Regional instance availability: Pending

## 3. Cost Review

- AWS Pricing Calculator reviewed: Pending
- Estimated test duration: Pending
- Estimated total cost: Pending
- AWS budget/alerts configured: Pending
- Cleanup responsibility: Pending

## 4. Security Review

- EC2 has no public IP.
- RDS has no public access.
- Database requires TLS.
- Application verifies the RDS certificate.
- AWS IAM roles are used instead of access keys.
- Private VPC endpoints are configured.
- Terraform state must be encrypted and protected.

Outstanding:
- Verify Linux bootstrap on target environment.
- Validate RDS TLS in a live session.
- Restrict API access before public exposure.
- Replace master DB credentials with a
  least-privilege application account.
- Review logging for sensitive information.

## 5. Planned Deployment Sequence

Phase 0:
Prepare private encrypted Terraform state and
state locking. Approve the cost estimate.

Phase 1:
Deploy Tokyo networking and foundational IAM.

Phase 2:
Deploy approved private endpoints, RDS,
artifact bucket, and monitoring resources.

Phase 3:
Upload the tested application bundle to S3.
Record its exact SHA256 checksum.

Phase 4:
Enable EC2 only after bootstrap dependencies
and readiness controls are verified.

Phase 5:
Test SSM, application health, RDS TLS,
synthetic writes/reads, and monitoring.

Phase 6:
Capture sanitized audit evidence.

Phase 7:
Remove application artifacts, destroy lab
infrastructure, and verify cleanup.

## 6. Deployment Status

NOT DEPLOYED

No live infrastructure results are claimed.
