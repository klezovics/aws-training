# ECS
# ECS Concepts
ECS = allow to run containers
ECS = simpler K8S basically
ECS inputs = containers + how to run them
ECS cluster = where your containers run

Concepts:
- Container definition -> where you container comes from and exposed ports.
- Task definition -> one or more containers. Its like the app itself. TASK ROLE key concept!! Other stuff like resources.
- Service definition -> how to scale your task. Wraps your task. Restarts, HA.

# ECS cluster modes:
- EC2 mode -> you manage the instances in the cluster. More admin overhead. Can scale in/out.
- Fargate -> no instance to manage. Less admin overhead. Kind of serverless. Pay only for deployed containers.
- ECS anywhere -> can run stuff on-prem

- Fargate containers -> injected into your VPC subnets via ENI. But run on Fargate external platform.


Have containers -> always go for ECS
ECS EC2 mode -> large workload, need to save money
Fargate -> if want less ops go for this. Small/burst workloads. Batch/periodic workload when necessary.

# ECR
- Like DockerHub, but only private in AWS. IAM integrated for access checks.
- Public and private registries. Inside each registry many repositories
- By default you have 1 private and 1 public repo.

Features:
- Security scanning. Basic and advanced. Scans by layer.
- Near real-time metrics. Can send events notifcation
- Can do cross-region/cross-account replication of images

# EKS
- EKS = Managed Kubernetes as a service + amazing integration with AWS services
- EKS Cluster = EKS Control Plane + EKS Nodes

## EKS Control Plane
- EKS Control plane = managed, runs on multi-AZ
- VPCs = AWS Managed VPCs (control plane run by amazon) + Customer VPCs (EC2 instances as worker nodes)

## EKS  Worker nodes
- EKS nodes can run in many places: AWS, Outposts, EKS Anywhere, Etc
- EKS Nodes = Self-managed, Managed node groups, Fargate pods -> check node type for your use case (KEY SELECTION!!)
- Many storage providers: EBS, EFS, etc ...
- Networking: either control plane ENIs injected into worker nodes or public endpoint for control plane