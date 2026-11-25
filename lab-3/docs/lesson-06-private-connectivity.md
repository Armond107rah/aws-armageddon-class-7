
# Lesson 6 — Tokyo Private AWS Connectivity

## Business Requirement

Prepare the Tokyo application to access required
AWS services without public EC2 exposure.

## Infrastructure Configuration

- AWS Region: ap-northeast-1
- Private VPC interface endpoints
- S3 gateway endpoint
- Restricted endpoint security group
- Private DNS enabled
- No public EC2 IP
- No inbound SSH rule

## AWS Service Endpoints

- Systems Manager: ssm
- Session Manager: ssmmessages
- Secrets Manager: secretsmanager
- CloudWatch Logs: logs
- CloudWatch Metrics: monitoring
- Amazon S3: Gateway endpoint

## Security Controls

Application outbound HTTPS is restricted to
the approved endpoint security group.

Endpoint inbound HTTPS permits traffic from
the Tokyo application security group.

EC2 uses an IAM instance profile rather than
static AWS credentials.

## Deployment Blockers

- Enforce and verify RDS MySQL TLS.
- Resolve private application dependencies.
- Complete CloudWatch IAM and logging setup.
- Implement application access controls.
- Integrate the application load balancer.
- Approve deployment costs and teardown steps.

## Verification

Terraform formatting: Pending
Terraform initialization: Pending
Terraform validation: Pending
AWS deployment: Not performed

## Business Value

The design supports private service access,
controlled network boundaries, least-privilege
architecture, and auditable infrastructure.

This is a lab environment, not a certified
production healthcare system.
