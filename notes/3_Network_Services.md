# Network
Here's a global overview
Networking has 3 kinds:
- Within 1 VPC
- Between 2+ VPCs
- VPCs and outside world



# VPC aspects
VPC aspects:
- VPC archtecture -> VPC list, divison to subnets, which subnet in which AZ
- Routing/access -> ensure there's a valid route connecting all necessary stuff
- Access control -> SGs/NACLs, firewalling and secure access
- DNS -> minor topic

VPC
├── Addressing        CIDR, IPv6, EIP, auto-assign
├── Segmentation      Subnets (AZ-bound), Route tables, ENI
├── Security          SG (stateful, ENI), NACL (stateless, subnet)
├── Egress/Ingress    IGW, NAT GW, EGW
├── Private/Hybrid    Endpoints, Peering, TGW, VPN, DX
├── DNS               resolver, DHCP options
└── Observability     Flow Logs, Mirroring

# VPC logical resources
- Region = container for VPCs
- VPC = container for subnets
- Subnets = container for ENIs

## VPC level
- VPC
- Subnets

## Subnet level
- Routing table

## ENI level
- ENI
VPC structure:
- VPC
- 
- Routing tables
- ENI

Security:
- SG
- NACL

Public connectivity:
- IGW/Egress-only IGW
- NAT GW
- Elastic IP

# Understanding Subnets
Subnet = container for ENI

Key props:
- AZ -> determines access to EBS volumes 
- CIDR range/IPv6 range -> its size (immutable after creation)
- Distinct routing table -> key advantage (?)
- Distinct NACL -> typically left on PERMIT ALL
- Auto-assign Public IPv4 flag


What makes networking simple:
- Only two firewall primitives: SG and NACL

## SERVICES (own API namespace, own console entry)
Grouped by the 3 kinds above.

### 1. Within 1 VPC
- VPC -> king of network services. Defines most stuff (subnets, routing, SG/NACL).
- ELB -> distributes traffic to your private compute. Types: ALB / NLB / GWLB.
  Internet-facing ones straddle kind 3, but the targets always live in your VPC.
- Cloud Map -> service discovery (registry of live task IPs)
- AWS Network Firewall (marginal) -> managed stateful firewall for a whole VPC (IPS/IDS, domain filtering).
  Sits above SG/NACL: SG is per-ENI, NACL is per-subnet, Network Firewall is per-VPC with deep inspection.

### 2. Between 2+ VPCs
- Transit Gateway -> hub-and-spoke router for many VPCs + on-prem. Transitive.
  Its route tables are also how you STOP VPCs reaching each other (segmentation).
- (VPC peering and PrivateLink do this too, but they are components, not services -> see below)
- Cloud WAN (marginal) -> managed global WAN, builds/monitors a multi-region network from a central policy.
  Think "Transit Gateway, but global and policy-driven". Rare on the exam.

### 3. VPC <-> outside world
The bucket splits by WHAT the other end is. Mixing these up is where exam questions bite.

a) The internet, INBOUND (the edge layer):
- CloudFront -> CDN + TLS + edge compute. HTTP(S) only.
- Global Accelerator -> anycast static IPs on the AWS backbone. CloudFront's L4 sibling, non-HTTP.
- API Gateway -> kind of like an ingress controller. Turns a Lambda into an API.

b) The internet, OUTBOUND: no service, only components -> IGW / NAT GW / egress-only IGW.

c) Your datacenter or your laptops:
- Direct Connect -> dedicated fiber to AWS. Private, not over the internet.
- Client VPN -> remote EMPLOYEES get into the VPC (vs Site-to-Site = office/DC into the VPC)

d) AWS public services (S3, DynamoDB, SSM, most APIs): no service, only components -> VPC endpoints.
   These live OUTSIDE your VPC on the AWS public zone. "Outside the VPC" != "on the internet".

### Cross-cutting (not a path, they attach to one)
- Route53 -> DNS. Tells clients WHERE to connect. Traffic never passes through it.
- WAF -> L7 request filtering. Attaches to CloudFront / ALB / REST API.
- Shield -> DDoS protection. Standard free+automatic, Advanced paid.

## CONCEPTS / COMPONENTS (resources INSIDE a service, not services themselves)
Inside VPC:
- Subnet, route table, ENI
- IGW, NAT gateway, egress-only IGW
- Security group (stateful, allow-only), NACL (stateless, allow+deny)
- VPC endpoint (gateway / interface aka PrivateLink)
- VPC peering, Transit Gateway ATTACHMENT, Site-to-Site VPN connection

Inside Route53:
- Hosted zone, record, alias, routing policy, health check

Inside ELB:
- Listener, target group

Inside API Gateway:
- Route, integration, stage, custom domain, authorizer, VPC link

# Detailed services overview
## Route53
- Route53 = DNS. Global service, globally resilient.
- Route53 = registrar (sells domains) AND authoritative nameserver (hosts the zone). Two separate roles.
- Hosted zone = one zone = the domain minus any subdomain you delegated away
  - creates SOA + NS records automatically; the 4 NS records go to your registrar
  - public hosted zone = answers the internet
  - private hosted zone = answers only inside associated VPCs (needs enableDnsSupport + enableDnsHostnames)
  - split-horizon = same name public + private, private wins inside the VPC
- $0.50/month per hosted zone + per-query charge

### Routing policies (heavily tested)
- Simple -> one record, no logic
- Weighted -> split traffic by % (canary, A/B)
- Latency -> send to the region with lowest latency for that user
- Failover -> primary + secondary, driven by a health check
- Geolocation -> route by user country/continent (compliance, localisation)
- Geoproximity -> route by distance, with a bias knob
- Multivalue -> return up to 8 healthy records, poor man's load balancing

### Health checks
- Probe from multiple global locations; unhealthy records drop out of answers
- Can check an endpoint, another health check (calculated), or a CloudWatch alarm
- This is what makes failover automatic instead of you editing records

### Records / TTL
- Alias record = AWS-specific, free, works at the zone apex, points at ALB/CloudFront/API GW/S3
- CNAME cannot be used at the apex -> use Alias
- Change is instant at Route 53; resolvers cache for the TTL (default 300s)
- Lower TTL to 60 a day BEFORE a planned migration
- Browsers cache ~60s on top of that; HTTP keep-alive can outlast the DNS change

## VPC
- VPC lives in a region
- VPC<->IGW = 1:1 relationship. VPC can have at most 1 IGW. IGW is attached to at most 1 VPC.
- VPC spans several AZs and can have subnets in them
- Subnet is pinned to exactly ONE AZ, forever
- All private services have their ENI in your VPC
- AZ is NOT inside the VPC. Subnet = intersection of (VPC, AZ). It is a lattice, not a tree.

VPC internals contain
- Subnets, route tables, IGW, NAT gateway, egress-only IGW (IPv6)
- Security groups (stateful, allow-only) and NACLs (stateless, allow+deny)
- "Public subnet" is not a checkbox: it just means the route table has 0.0.0.0/0 -> igw

## ELB family
- ALB = L7 (HTTP/HTTPS). Routes on path, host, header, method. Terminates TLS with ACM.
  - ALB ≈ Ingress in k8s. The TARGET GROUP ≈ Service (it tracks the healthy IPs).
  - Allows to expose thingies with private IPs (EC2/Fargate) to API Gateway or the internet
  - internal vs internet-facing is FIXED at creation
- NLB = L4 (TCP/UDP/TLS). Port-only routing. Static IP per AZ, EIP support. Very low latency.
- GWLB = L3. Inserts third-party firewall/inspection appliances into the traffic path.
- CLB = legacy, do not use.

Exam tells: "static IP" -> NLB. "route by URL path" -> ALB. "non-HTTP protocol" -> NLB.

## API Gateway
- API Gateway = Gates, the entry point. Auth/Validation/Rejection happens here.
- API Gateway = Kind of like Nginx ingress controller in k8s
- API Gateway = DNS Name + Auth + Routing rules + Backends
- Routes traffic to -> Lambda, ALB/NLB/CloudMap (via VPC link), Any public HTTP endpoint, AWS services
- HTTPS only. No port 80, no redirect. Put CloudFront or an ALB in front if you need it.
- Takes over authN (JWT/IAM/Cognito). Does NOT take over business authorisation.
- HTTP API (v2) = cheap, fast, fewer features. REST API (v1) = caching, API keys, WAF, mapping templates, ~3x price.

## VPC Link
- Allows public zone AWS services (like API Gateway) to reach into your VPC
- Provisions ENIs in YOUR subnets with a security group you choose
- Targets: ALB, NLB, or Cloud Map service (HTTP API). NLB only for REST API.
- Cannot target a raw private IP: it needs something that tracks which IPs are alive + healthy

## CloudFront
- CloudFront = CDN (caches your content at 600+ edge locations)
- CloudFront = can act as 80->443 redirect in front of API Gateway
- CloudFront = can do L7 filtering, WAF, a lot of stuff. Its the whole edge layer
- OAC = keeps the S3 bucket fully private while CloudFront serves it publicly
- Certs for CloudFront MUST live in us-east-1
- Global service

## Connectivity
- VPC endpoints — gateway (S3/DynamoDB, free, route table entry) and interface/PrivateLink (ENI in your subnet)
- VPC peering — 1:1, non-transitive, no overlapping CIDRs
- Transit Gateway — hub-and-spoke for many VPCs, transitive. Scales where peering does not
  (peering is 1:1 and non-transitive, so N VPCs need N(N-1)/2 links)
- Direct Connect — dedicated fiber to AWS
- Site-to-Site VPN — IPsec over internet, connects an office/DC to the VPC
- Client VPN — OpenVPN-based, connects individual laptops to the VPC

## Global
- Global Accelerator — anycast static IPs, AWS backbone for non-HTTP traffic (CloudFront's L4 sibling)

## Security layers (L7 -> L3)
Services:
- WAF   = L7, blocks bad REQUESTS (SQLi, XSS, bots, rate limits). Attaches to CloudFront/ALB/REST API.
- Shield = L3/4, blocks DDoS. Standard is free+automatic, Advanced is paid.

VPC components (not services):
- Security group = L3/4, stateful, allow-only, attaches to an ENI
- NACL           = L3/4, stateless, allow+deny, attaches to a subnet
