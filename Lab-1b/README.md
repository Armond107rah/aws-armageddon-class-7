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
