# Public vs Private Services
- Each service is born in the public zone or private zone. This is predecided for you by AWS.
- Public or Private service is networking perspective
- Private services live in a VPC
- Permissions vs Networking are two axis of public/private
- N.B. Public service means network reachability, not permissions
- IGW = Internet Gateway. Connects VPC to AWS Public zone and public internet. 1:1 relationship with VPC.
- The default VPC comes with an IGW pre-configured. If you delete it, no internet for the VPC.

![aws-network-zones.png](img/aws-network-zones.png)
## Service alchemy
- You can reach into a public service privately via a VPC gateway/interface endpoint -> traffic never goes to public internet
- You can expose a private service publicly by attaching an internet gateway to it and a public IP

Internet zones:
- Public internet
- Private internet -> VPCs
- AWS Public zone -> AWS public services live here (S3 as an example)
- VPCs are fully isolated and cannot talk to each other unless allowed
- Nothing can "reach into" a VPC unless allowed

# AWS Global Infra