# AWS Armageddon — Lab 1C Bonus B: HTTPS ALB, WAF and Monitoring

> **Outcome:** Extended the private-EC2 Bonus A architecture with a public Application Load Balancer (ALB), a Route 53 subdomain, ACM-managed HTTPS, AWS WAF, and two new CloudWatch 5XX alarms connected to SNS. **Status: Terraform configuration validated and deployment reported; end-to-end post-deployment checks require separate verification evidence.**

**Stack:** Terraform · AWS ALB · Target Groups · EC2 · RDS MySQL · Route 53 · ACM · AWS WAF · CloudWatch · SNS · VPC Endpoints · Systems Manager
**Region:** `us-east-1` · **Lab hostname:** `lab1c.epicreads.us` · **Branch:** `lab-1C-bonus-B`

![Bonus B architecture](evidence/diagrams/bonus-b.png)

## 1. Business problem and solution

Bonus A improved security by moving Flask onto a private EC2 instance. The tradeoff: end users could no longer reach the app directly. A business still needs a **secure, controlled public endpoint** that preserves the private compute and database layers, applies web-layer protection, and provides visibility when requests fail.

**Solution:** Expose an **internet-facing Application Load Balancer**, not the EC2 server. Terminate HTTPS at the ALB using an ACM certificate. Register private EC2 in a target group, inspect traffic with AWS WAF, and alert on 5XX conditions using CloudWatch and SNS.

## 2. What Bonus B adds

| Component | Function and boundary |
| --- | --- |
| Route 53 | DNS alias for `lab1c.epicreads.us` to the ALB; separate from the existing EpicReads root website |
| AWS Certificate Manager | DNS-validated TLS certificate for the lab hostname |
| Internet-facing ALB | Runs across **two public subnets**; accepts client HTTPS on TCP/443 |
| HTTP listener | Redirects HTTP TCP/80 to HTTPS with HTTP 301 |
| Target group | Registers **private EC2** and checks `GET /health` for HTTP 200 |
| Security groups | Public clients reach **ALB**; **only ALB SG** may reach EC2 on port 80; RDS stays EC2-only on 3306 |
| AWS WAF Web ACL | Regional ACL associated with ALB; AWS Common Rule Set in **Count mode**, separate IP rate-limit rule configured to block |
| CloudWatch | Two 5XX alarms: `HTTPCode_ELB_5XX_Count` and `HTTPCode_Target_5XX_Count` |
| SNS | Existing Lab 1C topic receives actions from both ALB-related alarms |

**Important encryption detail:** The browser-to-ALB connection is HTTPS; the deployed target group uses **HTTP from ALB to private EC2**. It is inaccurate to describe this implementation as end-to-end TLS.

## 3. Request and security flow

1. A browser resolves `lab1c.epicreads.us` using Route 53. The alias directs it to the internet-facing ALB.
2. The ALB uses the DNS-validated ACM certificate for TLS. HTTP requests to port 80 receive a redirect to HTTPS port 443.
3. AWS WAF evaluates ALB requests. The **AWS managed Common Rule Set is in Count mode** (observes matches; it does not enforce the managed group’s normal blocks yet). The custom rate-based rule blocks clients after exceeding the configured request threshold.
4. The ALB forwards accepted traffic to the single private EC2 instance via HTTP port 80. The target group uses `/health` for health checks; this is **not an auto-scaling or multi-target deployment**.
5. Flask accesses RDS MySQL in private subnets on TCP 3306. The EC2 application still uses Parameter Store, Secrets Manager, and its IAM role.
6. CloudWatch records ALB-generated and backend-generated 5XX metrics independently; both alarms have SNS actions configured. Email delivery requires a **confirmed SNS subscription**.

## 4. Terraform layout

Bonus B builds on Bonus A's modules and adds:

```text
Lab-1C/
├── main.tf                         # Existing networking, compute, RDS, IAM, monitoring
├── bonus_b.tf                      # New ALB module, EC2 SG ingress, target attachment
├── https.tf                        # ACM validation, HTTPS DNS alias
├── waf.tf                          # Regional Web ACL and ALB association
├── monitoring_bonus_b.tf           # ALB/target 5XX alarms using SNS
└── modules/
    └── load_balancer/
        ├── variables.tf
        ├── main.tf                  # ALB, SG, target group, listeners
        └── outputs.tf              # ALB DNS, zone ID, ARNs, ARN suffix
```

Module interface reuses `module.networking.vpc_id`, `module.networking.public_subnet_ids`, `module.compute.instance_id`, `module.compute.security_group_id`, and `module.monitoring.sns_topic_arn`.

The certificate and DNS validation records live in Route 53 hosted zone `epicreads.us`. The lab uses its own subdomain; **do not overwrite** existing root/apex website records.

## 5. Deployment record and verification status

The final pre-apply Terraform plan was **64 to add, 0 to change, 0 to destroy**. An `apply` was subsequently reported as executed. A plan and an apply are **not equivalent to verified application health**; capture the post-apply results below before marking Bonus B complete.

| Verification | Required result | Status in this write-up |
| --- | --- | --- |
| Terraform | Resources in state; successful apply | Apply reported; exact final output not provided here |
| ALB | State `active`, scheme `internet-facing` | Pending evidence |
| Target health | EC2 target `healthy` | Pending evidence |
| HTTP redirect | 301 from `http://lab1c.epicreads.us/health` | Pending evidence |
| HTTPS certificate | Trusted TLS, `/health` HTTP 200 | Pending evidence |
| Database readiness | `/ready` HTTP 200 | Pending evidence |
| Private EC2 | Private IPv4 and **no public IPv4** | Pending Bonus B evidence |
| AWS WAF | Web ACL attached to ALB | Pending evidence |
| CloudWatch | Two ALB/target 5XX alarms present | Pending evidence |
| SNS | Subscription confirmed; delivery tested | Pending evidence |

Evidence folder: [Bonus B screenshots](evidence/screenshots/bonus-b/). Add only screenshots from completed, real checks. Do not publish AWS credentials or secret values.

### Reproduce key tests

Run from your local terminal after Terraform deployment in the **correct state-backed directory**:

```bash
terraform validate
terraform state list
terraform output -raw alb_dns_name

# DNS, HTTP redirect, and trusted TLS (do not use curl -k)
dig +short lab1c.epicreads.us
curl -I http://lab1c.epicreads.us/health
curl -i https://lab1c.epicreads.us/health
curl -i https://lab1c.epicreads.us/ready

# Check the two CloudWatch alarms
aws cloudwatch describe-alarms --region us-east-1 \
  --alarm-names lab1c-bonus-b-alb-5xx lab1c-bonus-b-app-5xx \
  --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table
```

Inspect the ALB target group health, WAF association, security-group rules and CloudWatch alarm actions in CLI or AWS Console. The ALB must show a healthy target; a 200 from `/health` tests the app, while a 200 from `/ready` additionally tests the RDS path.

## 6. Security tradeoffs and improvement backlog

- **WAF Count mode:** The managed Common Rule Set currently logs/counts matches rather than enforcing its normal block behavior. Review false positives before switching to enforcement.
- **Public API endpoints:** Do not expose unauthenticated `/init`, `/add`, `/list` for real business data. Add authentication, authorization, request validation, and appropriate rate limits first. Prefer testing writes via Session Manager.
- **TLS scope:** This design secures **client → ALB**. For stronger in-transit protection, configure HTTPS between ALB and EC2 as a later enhancement.
- **High availability:** Two public ALB subnets do not create redundant application instances. The deployed target group uses one EC2 instance; add an Auto Scaling group and resilient app tier for real HA.
- **Observability:** 5XX alarms are early signals. Consider ALB access logging, target response-time dashboards, SNS delivery checks, runbooks, and synthetic application checks.
- **Cost:** ALB, WAF, NAT, RDS, interface endpoints, and other AWS services accrue charges while deployed.

## 7. Troubleshooting guide

| Symptom | First checks |
| --- | --- |
| Certificate stuck pending | ACM DNS validation CNAME in authoritative hosted zone; certificate Region `us-east-1` |
| DNS not resolving | `lab1c.epicreads.us` Route 53 alias, hosted zone delegation, DNS propagation |
| ALB target unhealthy | EC2 security group permits ALB SG on 80; `/health` returns 200; Apache/Gunicorn startup |
| HTTPS returns 502/503 | Target group health, app listener, bootstrap logs, target registration |
| `/health` works, `/ready` fails | RDS status, 3306 SG, SSM parameter paths, Secrets Manager IAM |
| WAF unexpectedly blocks requests | Inspect rule match and sampled requests; distinguish Count vs Block actions |
| No email on 5XX | Check alarms' `alarm_actions`, SNS subscription confirmation, and alarm state transitions |

## 8. Cleanup and Git branching

After capturing evidence, run `terraform plan -destroy`, review the exact resources, then `terraform destroy` **only from the same Terraform state/backend used to deploy Bonus B**. Confirm billable AWS resources have been deleted. Validate that cleanup does not disrupt other EpicReads services; the hosted zone itself and existing website records are outside this lab.

Never commit `terraform.tfstate*`, `terraform.tfvars`, `.terraform/`, plan files, API keys, or secrets. Preserve Core on `lab-1C`, Bonus A on `lab-1C-bonus-A`, and Bonus B on `lab-1C-bonus-B`. The READMEs and diagrams document the architecture; the actual Terraform `.tf` files are the deployment source of truth.
