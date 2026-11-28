
# Lesson 12 — Tokyo Private Application Deployment

## Objective
Deploy a Flask application on private Amazon EC2
and securely connect it to Tokyo RDS MySQL.

## Architecture
- AWS Region: ap-northeast-1
- EC2: Amazon Linux 2023, t3.micro
- Application: Python Flask + Gunicorn
- Database: RDS MySQL 8.4
- Artifact delivery: Private S3
- EC2 access: AWS Session Manager
- Database encryption: TLS
- Monitoring: Amazon CloudWatch

## Deployment Verification
- EC2 running: Pending
- Flask /health HTTP 200: Pending
- RDS /ready HTTP 200: Pending
- Synthetic CREATE / INSERT / SELECT: Pending
- TLS session verified: Pending
- CloudWatch logs received: Pending

## Troubleshooting
Document any actual errors, their root cause,
the corrective action, and verification results.

## Security Value
- EC2 does not require a public IPv4 address
- No SSH inbound port is required
- Application uses IAM permissions
- RDS is private
- TLS certificate verification is enabled
- No real patient data is used

## Outstanding Work
- Cross-region São Paulo application
- Transit Gateway peering and routes
- CloudFront and WAF
- CloudTrail and audit evidence
- API authentication and least-privilege DB user

## Cost Control
Record deployment date and time, active AWS
resources, expected costs, and cleanup plan.

## Status
Update only with verified test results.
