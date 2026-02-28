## Restore Operations, Secrets & Incident Response
Prerequisite: Lab 1a (EC2 -> RDS integration completed and verified)

## Project Overview
In Lab 1A, we deployed a secure EC2 installed with RDS architecture in AWS. 
In Lab 1B, we operate, observe, intentionally break and recover that system.
This lab introduces:
- Dual secret storage (Parameter Store & Secrets Manager)
- Centralized logging (Cloudwatch Logs)
- Automated alarms (Cloudwatch Alarm & SNS)
- Recovery without redeployment
This simulates real production on-call workflows.
In Lab 1A, we successfully deployed a working three tier architecture utilizing an EC2 with an attached RDS.
However, the most essential part as a cloud engineer is how robust that architecture is and how well they can survive failure.
Lab 1B transitions us from building infrastructure to operating it under real world conditions.
We introduce a clear separation of concerns by storing configuration values such as database endpoint, port, and name in Parameter Store,
while isolating sensitive credentials like usernames and passwords in Secrets Manager. this intentional separation reflects how mature environments manage configuration to reduce blast radius and improve security.
By centralizing application logs in Cloudwatch and creating alarms that trigger on database failures, we move from reactive troubleshooting to proactive observability.
In real production environments, outages are rarely caused by faulty code; they are usually caused by credential drift, access misconfiguration, or silent connectivity failures.
This lab simulates those exact failure patterns and forces recovery without redeploying infrastructure, mirroring on-call response workflows.
Instead of guessing fixes, we will diagnose issues using logs, retrieve known-good configuration from secure stores, and restore service methodically.

## Architecture Evolution Flow

User --> EC2 Application --> Parameter Store (endpoint, port, name) --> Secrets Manager (username, password) --> RDS MySQL --> Cloudwatch Logs --> Cloudwatch Alarms --> SNS Notification

## Part 1- Incident Scenario

Incident title: Database Connectivity Failure leads to Production Application Unavailable
## Symptoms Reported
- Application intermittently returns errors
- /list endpoint fails or hangs
- No recent code changes
- EC2 instance is still running
  You will not recreate the EC2, RDS, Hardcode credentials. We will use logs, alarms, use stored configuration values.

  ## Part 2 - Incident Injection
  One of the following failures will be injected:
  - Option A: Change DB password in Secrets Manager (Do not update actual RDS password)
  - Option B: Remove EC2 security group from RDS inbound rule (TCP 3306). This causes network isolation
  - Option C: Stop RDS instance entirely

  ## Part 3 - Monitoring & Alertine
  Step 1: Create SNS Topic
  ```bash
  aws sns create-topic --name lab-db-incidents
  ```
  Step 2: Subscribe Email
  ```bash
  aws sns subscribe \
  --topic-arn <TOPIC_ARN> \
  --protocol email \
  --notification-endpoint your-email@example.com
  ```
  Step 3: Create CloudWatch Alarm
  ```bash
  aws cloudwatch put-metric-alarm \
  --alarm-name lab-db-connection-failure \
  --metric-name DBConnectionErrors \
  --namespace Lab/RDSApp \
  --statistic Sum \
  --period 300 \
  --threshold 3 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --alarm-actions <SNS_TOPIC_ARN>
  ```
  Trigger when DB connection errors are greater than 3 within 5 minutes. It should be expected taht Alarm enters ALARM state and an SNS email is sent.
  ## Manadatory Incident Runbook
  Section 1: Acknowledge
  ```bash
  aws cloudwatch describe-alarms \
  --alarm-name lab-db-connection-failure \
  --query "MetricAlarms[].StateValue"
  ```
  The Alarm word should pop up in your terminal.
  Section 2: Observe
  
 ## Configuration Artifacts
 We will create Parameter Store Entries. I utilized these three stored values
 ```bash
/lab1b/db/endpoint
/lab1b/db/name
/lab1b/db/port
```
Use your CLI to verify the endpoints. When you do so the correct DB endpoint, assigned port and database name should appear.
 ```bash
aws ssm get-parameters \
  --names /lab1b/db/endpoint /lab1b/db/port /lab1b/db/name \
  --with-decryption
```
![Results1](Lab-1b/cloudwatch_parameters.png)
## Secrets Manager Secret
Use the CLI to verify your secrets value
```bash
aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql
```
## IAM Validation (Critical)
From EC2:
```bash
aws ssm get-parameter --name /lab1b/db/endpoint
aws secretsmanager get-secret-value --secret-id lab/rds/mysql
```
Expected:
No AccessDeniedException
This confirms:
- IAM role attached properly
- Least privilege permissions configured correctly

  ## Observability - CloudWatch Logs
  Verify Log Group Exists
  ```bash
aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2/lab-rds-app
```

