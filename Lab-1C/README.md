# AWS Armageddon — Lab 1C: Modular Infrastructure with Terraform

## Project overview

I built an AWS application environment using **Terraform modules** instead of configuring each service manually. The goal was to deploy a working Flask API connected to a private MySQL database, manage access and credentials securely, and monitor the application for problems.

The project demonstrates a repeatable approach to cloud infrastructure: **plan the architecture, separate resources into modules, review changes, deploy, test, troubleshoot, and clean up**.

**Technologies:** Terraform, Amazon VPC, EC2, RDS MySQL, IAM, Systems Manager Parameter Store, Secrets Manager, CloudWatch, SNS, Apache, Gunicorn, Flask, and Python.

## What I built, how I built it, and why

### 1. Networking

**What:** A dedicated VPC with two public subnets, two private subnets, an internet gateway, and routing.

**How:** I created a Terraform networking module that provided the VPC and subnet IDs to the other modules.

**Why:** Separating public and private resources creates clearer network boundaries. The application server was accessible for testing, while the database remained private.

### 2. EC2 application server

**What:** An EC2 instance hosting a Flask API through Apache and Gunicorn.

**How:** Terraform provisioned the instance, assigned an IAM role, configured its security group, and automated application setup through a startup script. HTTP access was restricted to an approved IP address.

**Why:** Automated provisioning reduces repetitive manual work and allows the same application environment to be recreated consistently.

### 3. Private RDS database

**What:** An Amazon RDS MySQL database without public access.

**How:** Terraform placed RDS in private subnets and allowed MySQL traffic on port 3306 only from the application's security group.

**Why:** The application can reach the database without exposing MySQL directly to the internet.

### 4. Configuration and secrets

**What:** Database configuration in Parameter Store and RDS-managed credentials in Secrets Manager.

**How:** The EC2 application's IAM role allowed it to retrieve the required settings and secret. Terraform module outputs connected the resources without manually copying identifiers.

**Why:** This keeps passwords and AWS access keys out of application code and makes configuration easier to manage.

### 5. Monitoring and alerts

**What:** CloudWatch application logs, a database connection error alarm, and SNS email notifications.

**How:** I configured log delivery and an alarm that evaluates the custom `DBConnectionErrors` metric against a threshold of three errors in five minutes. The alarm was connected to an SNS email subscription.

**Why:** Logs help diagnose failures, while alarms and notifications help engineers respond when something requires attention.

## How I approached deployment

I organized the infrastructure by responsibility—networking, IAM, compute, database, configuration, and monitoring. Each module had clearly defined inputs and outputs. Before deploying, I formatted and validated the Terraform configuration and reviewed the execution plan to understand which AWS resources would be created or changed.

After deployment, I tested the Flask API, its connection to MySQL, and the monitoring workflow. This taught me that **successful provisioning is only the beginning; the application must also work correctly**.

## A troubleshooting lesson

The application's database readiness endpoint initially returned HTTP 503. CloudWatch logs revealed a Python `KeyError`. I traced the issue to three database parameters stored under `/lab-1c-learning/db/` instead of the application's expected `/lab/db/` path.

I corrected the paths in Terraform and updated the related IAM permissions. I reviewed the plan first to avoid replacing the working EC2 and RDS resources. Once the targeted changes were applied, database connectivity recovered.

**Key lesson:** Investigate the error, identify the cause, make the smallest safe change, and test again—rather than rebuilding everything.

## Outcome and next steps

Lab 1C delivered a working Flask API connected to private RDS MySQL, successful database operations, application logging, and verified CloudWatch-to-SNS notification testing. It also demonstrated how Terraform modules make an environment easier to organize, troubleshoot, and recreate.

This was a **disposable learning environment**, not a production-ready system. The application used restricted HTTP access and demonstration endpoints without authentication. The next stages will move EC2 into a private subnet, add VPC endpoints, and introduce an Application Load Balancer with HTTPS and stronger security controls.
