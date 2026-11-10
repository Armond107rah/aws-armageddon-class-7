# AWS Armageddon — Lab 1C Bonus A: Private EC2 and Session Manager

> **Outcome:** Strengthened a working Terraform-deployed Flask/MySQL application by moving the compute instance from a public subnet into a private subnet, removing its public IPv4 address, and administering it with AWS Systems Manager Session Manager. **Status: deployed and application tests verified during the lab.**

**Stack:** Terraform · AWS VPC · EC2 · RDS MySQL · IAM · AWS Systems Manager · VPC Endpoints · NAT Gateway · Parameter Store · Secrets Manager · CloudWatch · SNS
**Region:** `us-east-1` · **VPC:** `10.234.0.0/16` · **Branch:** `lab-1C-bonus-A`

![Bonus A architecture](evidence/diagrams/bonus-a.png)

## 1. Business problem and engineering goal

The **Core Lab 1C** design ran the Flask API on a publicly addressable EC2 instance while keeping RDS private. That helped prove end-to-end functionality, but it left an unnecessary public entry point on the application host. A common business requirement is to reduce exposure without sacrificing operations, database access, or monitoring.

**Goal:** Preserve the working Flask-to-MySQL API while making the application instance private. Administrators should still be able to diagnose problems without opening SSH or assigning a public IP.

## 2. What changed from Core

| Area | Core Lab 1C | Bonus A |
| --- | --- | --- |
| EC2 placement | Public subnet, public IPv4 | **Private subnet, no public IPv4** |
| App inbound HTTP | Client-to-EC2 access | **No direct internet HTTP ingress** |
| Administrator access | Application accessed via public endpoint | **AWS Systems Manager Session Manager** |
| Outbound package installation | Public EC2 connectivity | **NAT Gateway for private EC2 bootstrap** |
| AWS service access | AWS APIs through permitted connectivity | **VPC interface endpoints and S3 gateway endpoint** |
| RDS | Private subnet; MySQL TCP/3306 from EC2 SG | Remains private; same SG principle |
| Application & alerts | Flask, CloudWatch, SNS | Retained and retested |

The ALB is **not** part of Bonus A. Public browser access through a load balancer is added in [Bonus B](README-Bonus-B.md).

## 3. Architecture and request flow

1. A VPC contains two public and two private subnets across Availability Zones. Public subnets provide internet-routing infrastructure, including the NAT Gateway.
2. The Flask host runs on **private EC2**, uses an IAM instance profile, and has **no public IP**. It is not reachable directly from the internet.
3. The NAT Gateway supports the application's bootstrap packages and other required outbound internet access. It does not accept unsolicited inbound user connections to EC2.
4. AWS Systems Manager uses the instance's IAM permissions and private AWS service connectivity for administrative sessions. VPC endpoints include the Systems Manager services used by this build, plus supporting services such as Secrets Manager and CloudWatch Logs; S3 uses a gateway endpoint.
5. Flask reads connection settings from SSM Parameter Store (`/lab/db/*`) and RDS-managed credentials from Secrets Manager. It reaches the private RDS MySQL instance on TCP **3306**.
6. CloudWatch records application events and database-connection monitoring; SNS delivers incident notifications to a confirmed email subscriber.

**Security boundary:** No public-IP EC2 and no direct inbound SSH. Database inbound access remains limited to the EC2 security group. This is a lab architecture, not a production hardening certification.

## 4. Terraform implementation

Implemented using the existing project modules:

| Module | Purpose |
| --- | --- |
| `modules/networking/` | VPC, subnets, routes, Internet Gateway, NAT |
| `modules/compute/` | Private EC2, security group, bootstrap, instance profile |
| `modules/vpc_endpoints/` | Private AWS service endpoints and endpoint security group |
| `modules/database/` | Private RDS MySQL and database security group |
| `modules/iam/` | EC2 identity and scoped AWS permissions |
| `modules/parameters/` | SSM database parameters and secrets references |
| `modules/monitoring/` | CloudWatch logs, connection-error alarm, SNS |

The critical EC2 settings were `subnet_id = var.private_subnet_id` and `associate_public_ip_address = false`. The public HTTP ingress rule from Core was removed. Terraform module wiring passes `module.networking.private_subnet_ids[0]` to the compute module.

## 5. Validation evidence

The following checks were **reported as passed during Bonus A Lesson 3**:

| Test | Verified result |
| --- | --- |
| Terraform | Successful plan/apply for private architecture |
| EC2 network | Private IP present, **no public IP** |
| Administration | Connected with Session Manager without SSH |
| `GET /health` | HTTP 200 |
| `GET /ready` | HTTP 200 (database reachable) |
| `POST /init` | Notes table initialized |
| `POST /add` | Sample record inserted |
| `GET /list` | Sample record retrieved |
| CloudWatch | Fresh application log events observed |

Screenshots: [Bonus A evidence folder](evidence/screenshots/bonus-a/). The folder contains the actual captured images; do not add simulated screenshots or credentials.

### Reproduce the tests

From the **Terraform deployment directory**, not a GitHub clone without the intended state:

```bash
terraform init
terraform validate
terraform plan
# Review region, resources, state, and cost before running:
terraform apply
```

Use AWS Systems Manager Session Manager to access the private EC2 instance, then run **inside EC2**:

```bash
curl -i http://127.0.0.1/health
curl -i http://127.0.0.1/ready
curl -i -X POST http://127.0.0.1/init
curl -i -X POST http://127.0.0.1/add -H 'Content-Type: application/json' \
  -d '{"note":"Bonus A private EC2 test"}'
curl -i http://127.0.0.1/list
```

On the **local computer**:

```bash
aws logs tail /aws/ec2/lab-1c-learning-rds-app --region us-east-1 --since 30m
```

For a brief local browser test, an authenticated Session Manager port-forwarding session can tunnel to port 80 without exposing EC2 publicly.

## 6. Engineering decisions and troubleshooting

- **Why private EC2?** It removes a direct internet-reachable application host, while leaving outbound package installation and managed access available.
- **Why Session Manager?** Administrative access without inbound SSH or managing an externally exposed bastion host.
- **Why NAT and endpoints?** NAT handled application bootstrap to public package repositories; interface/gateway endpoints kept compatible AWS-service access private where supported. NAT and interface endpoints carry charges.
- **If SSM isn't Online:** Confirm `AmazonSSMManagedInstanceCore`, SSM endpoint connectivity, endpoint private DNS, and endpoint SG TCP/443 rules.
- **If `/ready` fails:** Inspect CloudWatch/application logs, `/lab/db/*` parameter names, IAM access to secrets, RDS SG TCP/3306, and RDS status. Core Lab 1C previously exposed how mismatched SSM parameter paths can affect readiness.
- **If `/health` fails:** Inspect `cloud-init` output, Apache/Gunicorn service state, and local app logs before blaming RDS.

## 7. Cost, cleanup, and repository discipline

This lab can accrue charges for EC2, RDS, NAT, VPC interface endpoints, data transfer, and logs. Preserve screenshots first; then, in the **same Terraform working directory and backend that deployed the resources**, review `terraform plan -destroy` and run `terraform destroy` when finished. Confirm resources are deleted in AWS.

Do **not** commit `.terraform/`, `terraform.tfstate*`, `terraform.tfvars`, plan files, private keys, or secrets. The original public EC2 architecture is preserved on the `lab-1C` branch; the Bonus A implementation belongs on `lab-1C-bonus-A`.

## 8. Resume at Bonus B

[Bonus B: ALB, HTTPS, WAF and monitoring](README-Bonus-B.md) adds a secure public entry point in front of the private application without assigning EC2 a public IP.
