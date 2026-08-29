# VPC Domain Model

VPC = your own private network inside one AWS region.
Everything with a private IP lives in it. Public-zone services (S3, SQS, DynamoDB) never do.

Companion to [1_IAM_Domain_Model.md](1_IAM_Domain_Model.md).

---

## 1. The shape

```
Account
  └── Region
        ├── VPC ──────┐
        ├── AZ ───────┤
        │             └── Subnet ── ENI ── EC2 / Fargate task / endpoint
        └── S3, SQS, DynamoDB        (public zone, NOT in your VPC)
```

Three facts that explain most confusion:

| Fact | Why it matters |
|---|---|
| A VPC **spans** AZs | The AZ is not "inside" the VPC. They are two independent axes. |
| A subnet = **one VPC × one AZ** | This is why HA always means "one subnet per AZ". Fixed at creation. |
| Everything private has an **ENI** | The ENI is the thing that has an IP and holds security groups. |

k8s analogy: VPC ≈ the cluster network, subnet ≈ a zone's node pool, ENI ≈ a pod's network interface.

---

## 2. The objects

| Object | Lives in | One-liner |
|---|---|---|
| **VPC** | Region | The network. CIDR `/16`–`/28`. Primary CIDR is immutable. |
| **Subnet** | One AZ | A slice of the VPC CIDR, pinned to one AZ forever. |
| **Route table** | VPC | Attached to subnets. Says where packets go. Longest prefix wins. |
| **ENI** | One AZ | The actual network card. Holds private IP, optional public IP, security groups. |

**Gotcha — 5 IPs are reserved per subnet.** First four + last address.
A `/24` gives you **251** usable, not 256.

**Gotcha — the `local` route.** Every route table has a route for the VPC CIDR.
You cannot delete or override it. That is why every subnet in a VPC can always reach
every other subnet (SGs and NACLs permitting).

---

## 3. Getting out of the VPC

By default a VPC is sealed. Nothing in, nothing out. You add exactly one of these.

### IGW — internet gateway

The door to the outside. One IGW ↔ one VPC. Regionally resilient.

Does **two** things:
1. Route target for internet + AWS public zone.
2. **Static 1:1 NAT** — maps the instance's private IP ↔ its public IP.

> The instance OS never sees its public IP. `ip addr` shows only the private one.
> The translation happens at the gateway.

### NAT gateway

Lets **private** subnets reach out. Outbound only — nothing can dial in.

| | |
|---|---|
| Where it lives | In a **public** subnet (not the private one it serves) |
| Needs | An Elastic IP |
| Scope | **One AZ.** One NAT gateway = SPOF + cross-AZ data charges. Use one per AZ. |
| Cost | Hourly **and** per GB processed — this is the expensive one |
| IP version | IPv4 only |

### Egress-only IGW

Same idea, for IPv6. No NAT (IPv6 is globally routable) — it just blocks inbound.

### NAT instance

Legacy. An EC2 doing NAT yourself. Only reason left: you need port forwarding or a bastion.

### The two rules to memorise

> **"Public subnet" is not a checkbox.**
> It just means the route table has `0.0.0.0/0 → igw-xxxx`.

> **An instance reaches the internet only if ALL FOUR are true:**
> IGW attached · route to it · public IP on the ENI · SG + NACL allow it.

---

## 4. Firewalls: SG vs NACL

| | Security group | NACL |
|---|---|---|
| Attaches to | **ENI** | **Subnet** |
| Stateful? | **Yes** — reply traffic is automatic | **No** — you need rules both directions |
| Can deny? | **No, allow-only** | **Yes** |
| Multiple rules | All SGs unioned, no order | Numbered, **first match wins** |
| How many | 5 per ENI (max 16) | 1 per subnet |

**SGs only ever widen.** Adding a second SG can never restrict anything, so there are no
conflicts and no ordering to reason about.

**SGs can point at other SGs.** This is the pattern you actually use:

```
internet → sg-alb → sg-web → sg-db
```
Each tier allows only from the tier in front. No IP addresses anywhere. Survives autoscaling.

**SGs cannot block anything.** No deny rule exists.
→ *"Block this one malicious IP"* is always **NACL**. That is the exam tell.

**Default SG** = allows all traffic from itself + all outbound.
You only get it if you specify no SG at launch.

---

## 5. Reaching AWS services privately

Problem: S3 is a public-zone service. Your instance is in a private subnet. How?

| | Gateway endpoint | Interface endpoint (PrivateLink) |
|---|---|---|
| Works for | **S3 + DynamoDB only** | Almost everything else |
| What it is | A **route table entry** | An **ENI with a private IP** in your subnet |
| DNS | Unchanged (still the public IP) | Private DNS → the ENI |
| Cost | **Free** | Hourly + per GB |
| From on-prem? | No | Yes (via DX/VPN) |
| Region | Same region only | — |

> A VPC with **no IGW and no NAT** can still call S3, SQS, KMS, and Secrets Manager —
> entirely through endpoints. That is the "fully private" architecture.

**Why you care:** without the S3 gateway endpoint, private-subnet traffic to S3 goes out the
NAT gateway and you pay per GB — for traffic that never leaves the AWS network anyway.
It is a bill fix as much as a security one.

---

## 6. Connecting to other networks

| Option | Direction | Key limitation |
|---|---|---|
| **VPC peering** | VPC ↔ VPC | **Non-transitive**, no overlapping CIDRs. *N* VPCs need *N(N−1)/2* links. |
| **Transit Gateway** | Hub for many | **Transitive**. This is what peering can't do. |
| **Site-to-Site VPN** | Office/DC → VPC | IPsec over the public internet. |
| **Client VPN** | Laptop → VPC | For individual remote employees. |
| **Direct Connect** | Fibre → VPC | Consistent latency. **Not encrypted by default.** |
| **VPC link** | API Gateway → **into** your VPC | The reverse direction. Targets ALB/NLB/Cloud Map, never a raw IP. |

---

## 7. DNS

- Resolver lives at **VPC base + 2** (`10.0.0.2` in a `10.0.0.0/16`). Also `169.254.169.253`.
- **`enableDnsSupport` + `enableDnsHostnames` must BOTH be on** — otherwise private hosted
  zones and interface-endpoint DNS silently do not work. **Check this first** when private
  DNS fails.
- **Private hosted zone** = resolves only inside the VPCs you associate.
- **Split-horizon** = same name in a public and a private zone. Inside the VPC, private wins.

---

## 8. Default VPC (know how it differs)

| | Default VPC | Custom VPC |
|---|---|---|
| CIDR | Always `172.31.0.0/16` | You choose |
| Subnets | One `/20` per AZ, rest unused | You choose |
| IGW | Attached | None until you add one |
| Auto-assign public IP | **On** | **Off** |

Consequence: every region's default VPC has the **same CIDR**, so they can never be peered.

Deletable. `aws ec2 create-default-vpc` brings it back.
Treat it as a scratchpad, not a foundation.

---

## 9. Scope cheat sheet

| Scope | Objects |
|---|---|
| **Region** | VPC, internet gateway |
| **VPC** | Route table, security group, NACL |
| **AZ** | Subnet, NAT gateway, ENI, EC2 instance, EBS volume |

Anything in the AZ row is a thing you must duplicate per AZ for high availability.

---

## 10. Debugging: what each failure looks like

| Symptom | It's almost certainly |
|---|---|
| Hangs, then times out | **No route** — missing NAT, endpoint, or route table entry |
| Times out, no error | **SG or NACL** dropping packets silently |
| Instant `AccessDenied` / `403` | **IAM** — not a networking problem at all |
| Auth/signature error | **Wrong regional endpoint** (region is baked into the SigV4 signature) |

> **Connectivity problems hang. Permission problems fail fast.**
> That one line will save you hours.

---

## Glossary

| | |
|---|---|
| **AZ** | Availability zone |
| **CIDR** | An IP range like `10.0.0.0/16` |
| **DX** | Direct Connect |
| **EIP** | Elastic IP — a static public IPv4 you own |
| **ENI** | Elastic network interface — the virtual network card |
| **IGW** | Internet gateway |
| **NACL** | Network access control list |
| **NAT / PAT** | Network / port address translation |
| **SPOF** | Single point of failure |
