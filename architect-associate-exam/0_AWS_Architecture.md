# Keu summary
## Fundamentals
- You need to understand fundamental resource hierarchy -> Organisation > OU > Account > Region > VPC > AZ > Subnet > Priv Services
- Each request to the AWS API is always directed at EXACTLY ONE service.
- There are exactly two ways to do auth: API keys or tokens from STS
- Each AWS API request = identity + action + resource. All policies attached to identity (in req context) are collected
- AZ works like this: Explicit Deny > Explicit Allow > Implicit Deny (by default everything is DENY)

Fundamental services:
- IAM -> fundamental in auth
- EC2 -> fundamental compute unit
- VPC -> most fundamental thing in networking
- S3 -> gateway to/from the cloud
- Secret Manager/Param store -> fundamental aspects of config
- CloudFormation -> allows to define IaC

## Key questions to ask per service
There are some fundamental questions you need to ask per-service

1. **Scope** -> global / regional / AZ.
   Tells you the resilience story and what a failure takes down.
   Global: IAM, Route 53, CloudFront, Organizations.
   Regional: S3, DynamoDB, SQS, Lambda, VPC.
   AZ: subnets, EC2 instances, EBS volumes, NAT gateways.

2. **Zone** -> public zone / private zone.
   Tells you how to connect to it.
   Public zone = has an endpoint, reach it via IGW, NAT or VPC endpoint (S3, SQS, DynamoDB).
   Private zone = you place it in a subnet (EC2, RDS, ElastiCache).
   The tell: if creating it asks for a VPC and subnets, it is private zone.

3. **Billing shape** -> per instance-hour / per request or GB.
   If it makes you pick an instance size, EC2 is underneath (RDS, ElastiCache, EMR, MSK).
   If it is priced per request or per GB, it is not (S3, DynamoDB, Lambda, SQS).

4. **Auth model** -> IAM only, or IAM plus a data-plane credential.
   Control plane is always IAM over HTTPS.
   Data plane may be something else entirely: Postgres user on 5432, SSH, Redis, NFS.

5. **Resource policy support** -> yes / no.
   Determines how cross-account sharing works.
   Yes -> attach a resource policy naming the other principal
   (S3, KMS, SQS, SNS, Lambda, Secrets Manager, ECR, API Gateway, EFS, IAM role trust policies).
   No -> share a role instead, not the resource
   (EC2, DynamoDB, RDS, EBS, CloudFront).

# Course structure
Let's divide the course in 3 parts and conquer them one by one

## Part 1 -> Fundamental services
So here the gameplan is like this

IAM intro -> Accounts, Orgs, OU, Identities and Permission policies. Practice with them. Control tower also goes here.
Compute -> EC2/Container services. Learn deeply what you can do with EC2 instances and a bit about running containers.
Networking -> Learn what a VPC is and its structure. Its containers and its structure (subnets) and how it can be configured
Storage -> S3 -> The data gateway. You can read/write key:object pairs. Deeply configurable. Practice all config knobs.
Ops -> CloudWatch and CloudTrail. Metrics, Logs and alerts.
Basic intro into CloudFormation is also here. 