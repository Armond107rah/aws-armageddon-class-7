# Lesson 10 — Controlled Tokyo Deployment

## Objective
Deploy foundational Tokyo networking and IAM
infrastructure using protected Terraform state.

## Terraform State
- Backend: Amazon S3
- Region: ap-northeast-1
- Key: lab3/tokyo/terraform.tfstate
- Encryption: SSE-S3
- Versioning: Enabled
- State locking: S3 native lockfile
- Public bucket access: Blocked

## Deployment Scope
- Tokyo VPC
- Public and private subnets
- Internet gateway and route tables
- IAM role and instance profile
- Application security group

## Excluded Resources
- RDS
- EC2
- NAT Gateway
- Interface VPC endpoints
- Transit Gateway
- CloudFront

## Verification
- Preflight: Pending
- State bucket protections: Pending
- Terraform plan: Pending
- Terraform apply: Not run
- Tokyo VPC verification: Pending
- Subnet verification: Pending

## Deployment Verification
AWS Region: Tokyo (ap-northeast-1)

Deployment method: Terraform using S3 remote state and native S3 locking.

## Resources verified
- Tokyo VPC created with CIDR 10.50.0.0/16
- Two public subnets created
- Two private subnets created
- Internet Gateway attached to the VPC
- Pubic and private route tables configured
- IAM role and instance profile created
- Application security group created
- No EC2 instance deployed
- No RDS database deployed
- No NAT Gateway deployed

## Terraform Results
- Plan: 17 resources added, changed 0, 0 destroyed
- Apply: Apply has been done
- Terraform state: has been verified
- AWS CLI: Verified

## Business and Security Value
This stage established an isolated AWS network in Tokyo, providing the foundation for deploying a private application and database.
Terraform was configured to manage infrastructure through version-controlled definitions and protected remote state.
Separating the networking deployment from the application and database deployments reduced troubleshooting complexity and gave us greater control over AWS costs.
