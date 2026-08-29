# Ops service list

## Observability
- CloudWatch -> the ops backbone. Three parts:
  - Metrics -> numeric time series. AWS services emit automatically; you can push custom ones.
  - Logs    -> ingestion + query (Log Insights). Metric filters turn log patterns INTO metrics.
  - Alarms  -> watch ONE metric, cross a threshold, DO something (SNS, Auto Scaling, EventBridge)
- CloudTrail -> audit log of API CALLS. Who did what, when, from where.
- X-Ray -> distributed tracing across services
- CloudWatch Agent -> needed for OS-level metrics (memory, disk free) — AWS cannot see inside your OS

CloudWatch = "how is it behaving". CloudTrail = "who did what".

## Management / fleet
- Systems Manager (SSM) -> the fleet management suite:
  - Session Manager   -> shell with NO key and NO inbound port
  - Parameter Store   -> free hierarchical config + SecureString secrets
  - Run Command       -> execute a script across many instances
  - Patch Manager     -> scheduled OS patching
  - State Manager     -> enforce desired config
  - Inventory         -> what software is installed where
  - Fleet Manager     -> browser RDP for Windows
- AWS Config -> records resource configuration OVER TIME + compliance rules. "Was this ever public?"
- Trusted Advisor -> canned checks: cost, security, limits, fault tolerance

## Governance
- Organizations -> accounts, OUs, SCPs, consolidated billing
- Control Tower -> managed landing zone. Sets up Orgs + Identity Center + org CloudTrail + Config + Account Factory
- Service Quotas -> view and request limit increases

## IaC / deployment
- CloudFormation -> declarative stacks. State is AWS-managed (no tfstate to lose).
- CDK -> CloudFormation generated from real code (TS/Python)
- SAM -> CloudFormation dialect for serverless
- Elastic Beanstalk -> PaaS-ish, legacy-feeling
- CodePipeline / CodeBuild / CodeDeploy -> AWS-native CI/CD

## Cost
- Cost Explorer -> where the money went
- Budgets -> alert (or act) when spend crosses a threshold
- Compute Optimizer -> right-sizing recommendations
- Savings Plans / Reserved Instances -> commitment discounts

## Backup / DR
- AWS Backup -> centralised backup policies across EBS, RDS, DynamoDB, EFS, S3
- RTO = how long you can be DOWN. RPO = how much DATA you can lose.
- DR strategies, cheapest -> most expensive:
  - Backup & restore   RTO hours-days   RPO hours
  - Pilot light        RTO tens of min  RPO minutes
  - Warm standby       RTO minutes      RPO seconds
  - Multi-site active  RTO ~0           RPO ~0

## Exam notes
- Alarms work off METRICS only. To alert on log content: log -> metric filter -> metric -> alarm.
- New alarm starts INSUFFICIENT_DATA. It stays there forever if the metric is never published.
  Fix with TreatMissingData (breaching / notBreaching) for heartbeat alarms.
- Time to fire = Period x EvaluationPeriods + metric publish latency.
  EC2 basic monitoring = 5 min. Detailed monitoring = 1 min (paid).
- Memory and disk-free are NOT default EC2 metrics — they need the CloudWatch Agent.
- CloudTrail: 90 days of management events free; create a Trail -> S3 for longer.
  Data events (S3 object-level, Lambda invokes) are OFF by default.
  Global service events (IAM, STS, CloudFront) land in us-east-1.
- Config answers "what did this look like last Tuesday", CloudTrail answers "who changed it".
