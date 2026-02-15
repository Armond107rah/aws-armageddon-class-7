md

#🚀 Lab 1a — Secure EC2 → RDS Integration

## Foundational AWS Cloud Application Architecture

---

## Project Overview

This lab demonstrates a production-style AWS backend architecture  where:


- Amazon EC2 runs an application server
- Amazon RDS (MySQL) serves as a managed database
- Security Groups enforce least privilege networking
- IAM roles eliminate static credentials
- AWS Secrets Manager securely stores database credentials


The objective is not application complexity — the objective is secure infrastructure design and verification.

This architecture pattern is used in:
- SaaS platforms  
- Enterprise backend services  
- DevOps environments  
- Cloud security assessments  
- Lift-and-shift workloads  

---

## 🏗 Architecture Overview

This lab was built using a layered cloud architecture model.  
Each layer enforces a specific responsibility and security boundary.

1. VPC creates the isolated network boundary (Network Foundation)
2. Security Groups define allowed communication (Nework Access Control)
3. RDS provides managed database in private subnet (Database Layer)
4. Create a Secrets Manager for credential secure storage 
5. EC2 application (Application Layer):
   - Retrieves DB credentials from Secrets Manager
   - Retrieves endpoint and port from Parameter Store

The system was built in the following order:
### Logical Flow

1. User sends HTTP request to EC2
2. EC2 application:
   - Retrieves DB credentials from Secrets Manager
   - Retrieves endpoint and port from Parameter Store
3. EC2 connects to private RDS endpoint
4. Database processes request
5. Response returned to user
---

## Architecture Screenshot
![VPC Architecture](Screenshots/vpc-structure.png)

## Creating a VPC
1. Connect to AWS and log in to your console.
2. Search for VPC and open the VPC dashboard.
3. Click on create VPC
4. Select VPC and more for VPC settings
5. Name your VPC <lab-1a-vpc>
6. Input your IPv4 CIDR block <10.234.0.0/16>
7. Select Number of Availability Zones (AZs) <3>
8. Select number of public and private subnets <3>
9. Click on customize subnets CIDR blocks and assign the CIDR blocks for each private and public subnet
10. Select Regional - New, for NAT gateways
11. Ensure that none is selected for VPC endpoints.
12. Click on Create VPC to create the VPC.

## Security Design
Security was implemented intentionally and mirrors production systems. Security Groups act as virtual firewalls. 

- Name: ec2-lab-sg
- Description: Security Group for lab1 EC2 Instance 
- VPC: lab-1a-vpc
- Inbound Rules: 
-      -Type: HTTP, Port 80, Source: Anywhere- IPv4 0.0.0.0/0, Description: HTTP
-      - Type: SSH, Port: 22, Source: MyIP(auto-detects your current IP)
-  Outbound rules: Default (allow all)

3. Click on Create security group

1. In the VPC dashboard, select Security Groups from the left menu.
2. Click on Create security group.


RDS inbound rule:

TCP 3306
Source = EC2 Security Group ID
No 0.0.0.0/0 exposure
EC2 handles public HTTP traffic

This enforces least-privilege communication.
Only the application server can reach the database.

![RDS Security Group](Screenshots/security-group.png)

---
### RDS- Managed Database Layer

Amazon RDS was configured:
-MySQL engine
-Private subnet
-Public access disabled
-Accessible only from EC2 security group
![RDS Instance](Screenshots/database-instnace.png)

Why is it essential?
In production:
1. You should not run databases directly on EC2
2. Managed services reduce operational burden
3. it improves reliability and security posture as it demonstrates separation of compute and data layers.

## Steps on creating a Database Security Group
1. In Aurora and RDS click on Subnet Groups in the left menu.
2. Click on Create DB Subnet Group
3. Fill in the Name and Description of your subnet group
4. Choose the appropriate VPC for your subnet group
5. Under the Add subnets heading, click select the Availability zones for your subnet
6. On the Subnets dropdown, select ONLY the private subnets associated with your availability zones selected earlier
7. In the Subnets selected box, review and confirm that only private subnets have been selected and then click create to complete the creation of your subnet group. 

## AWS Secrets Manager (Credential Storage)

AWS Secrets Manager securely stores sensitive information such as:
* Database passwords
* API Keys
* Tokens
* Certificates

It supports:
* Encryption at rest
* Versioning
* Rotation

It is essential because hardcoding passwords is a critical security flaw.

Without Secrets Manager:
* Credentials would live in code
* Rotating secrets would require redeployments
* Breaches would be harder to contain

In this Lab:
* DB credentials stored securely
* Application retrieves them dynamically
* No password stored in source code

This demonstrates secure configuration management.

## Identity & Credential Management

An IAM role is an AWS identitiy that grants permissions to resources.
Instead of storing AWS keys on the server:
* The EC2 instance assumes a role
* Temporary credentials are provided automatically

Without IAM roles:
* Static credentials must be stored
* Credential leakage risk increases
* Rotation becomes complex

In this lab: 
-EC2 uses an IAM instnace profile
-No static AWS credentials stored on server
-Secrets Manager stores database credentials
-Parameter Store stores non-secret configuration
-Application retrieves configuration dynamically at runtime



---
### Amazon EC2 (Compute Layer)
! [Amazon EC2](Screenshots/Ec2-instance-lab-1a.png)
Amazon EC2 provides scalable virtual compute instances
It runs on:
* Applications
* APIs
* Backend services
* Container runtimes

They are essential because EC2 serves as a compute layer that:
* Receives user requests
* Executes business logic
* Connects to backend services
* Returns responses

In this lab:
* EC2 hosted the web application
* EC2 was placed in public subnet
* EC2 connected privately to RDS

This models the real world pattern revolving public application layer and private database layer. 





