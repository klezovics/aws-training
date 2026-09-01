# ECS
# ECS Concepts
# ECS Cluster Mode
# ECR
- Like DockerHub, but only private in AWS
- Public and private registries. Inside each registry many repositories
- Public repo -> everyone can pull
- Private repo -> only authorized users can pull
- IAM integrated. Very nice.
- Security scanning. Basic and advanced. Scans by layer.
- Near real-time metrics.
- Can send events notifcation
- Can do cross-region/cross-account replication of images

# EKS
- Managed Kubernetes as a service
- Amazing integration with AWS services
- Can run in many places: AWS, Outposts, EKS Anywhere, Etc
- Control plane = managed, runs on multi-AZ
- EKS Cluster = EKS Control Plane + EKS Nodes
- EKS Nodes = Self-managed, Managed node groups, Fargate pods -> check node type for your use case (KEY SELECTION!!)
- Many storage providers: EBS, EFS, etc ...
- VPCs = AWS Managed VPCs (control plane run by amazon) + Customer VPCs (EC2 instances as worker nodes)
- Networking: either control plane ENIs injected into worker nodes or public endpoint for control plane