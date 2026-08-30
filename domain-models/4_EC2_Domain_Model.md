# EC2 Domain Model

EC2 = virtual machines in the private zone. Always inside a subnet, always inside one AZ.

---

## 1. The shape

```
Region
  └── AZ
        └── Subnet
              └── ENI ── Instance ── EBS volumes (same AZ)
                                  └── Instance store (ephemeral, on the host)
```

An instance is really an assembly of four independent things:

| Part              | Notes                                                                           |
|-------------------|---------------------------------------------------------------------------------|
| **AMI**           | The boot image. Regional — copy it to use elsewhere.                            |
| **Instance type** | CPU/RAM/network sizing                                                          |
| **ENI**           | Network identity. `eth0` is created with the instance and cannot be detached.   |
| **EBS volume(s)** | Storage. **AZ-locked** — a volume can only attach to an instance in its own AZ. |

---

## 2. Lifecycle

```
pending → running → stopping → stopped → (start again)
                  → shutting-down → terminated
```

| State          | Billing           | Root EBS               | Public IP             | Instance store |
|----------------|-------------------|------------------------|-----------------------|----------------|
| **running**    | compute + storage | kept                   | kept                  | kept           |
| **stopped**    | **storage only**  | kept                   | **lost** (unless EIP) | **wiped**      |
| **terminated** | none              | **deleted** by default | gone                  | gone           |

- **stopped** is restartable. **terminated** is permanent — different states on purpose.
- `terminated` lingers ~1 hour in `DescribeInstances` so automation can tell
  "gone as intended" from "bad instance ID".
- A stop/start usually moves the instance to a **different physical host**, which is why
  instance store is wiped and the public IP changes.
- `DisableApiTermination` blocks the terminate call. `DeleteOnTermination=false` on the
  root volume keeps the disk after the instance dies.

---

## 3. Storage

|             | EBS                                         | Instance store                  |
|-------------|---------------------------------------------|---------------------------------|
| Nature      | Network-attached                            | Physically attached to the host |
| Persistence | Survives stop and terminate (if configured) | **Wiped on stop AND terminate** |
| Scope       | **One AZ**                                  | The host                        |
| Snapshots   | Yes, to S3                                  | No                              |
| Resize      | Yes, live                                   | No                              |

**On terminate:**

- Root EBS volume → **deleted** (`DeleteOnTermination=true` by default)
- Extra EBS volumes → kept by default via the API; the console wizard often sets true — check
- Instance store → always gone
- Snapshots and AMIs → survive, billed separately

**EBS volume types:** `gp3` (default, decoupled IOPS/throughput), `io1`/`io2` (high IOPS,
Multi-Attach), `st1`/`sc1` (throughput HDD, cannot be a boot volume).

**Snapshots** are incremental and stored in S3 (AWS-managed, not your buckets).
Copy a snapshot to another region to move data across AZs/regions.

---

## 4. Networking

- Private IP: **always**, from the subnet, stable for the instance's life
- Public IPv4: **optional**, dynamic, **lost on stop/start**
- Elastic IP: static public IPv4 you own, survives stop/start
- The public IP is a **1:1 static NAT at the IGW** — the OS never sees it (`ip addr`
  shows only the private address)

To reach the internet you need **all four**: IGW attached, route to it, public IP, SG+NACL allow.

**Security groups attach to the ENI**, not the instance. 5 per ENI (max 16), unioned,
allow-only, stateful.

Multiple ENIs are possible (management vs data plane, or moving a private IP between
instances for failover). Only `eth0` is undetachable.

---

## 5. Identity — instance profile

EC2's API takes an **instance profile**, not a role. The profile is a wrapper holding
exactly one role.

```
Role (trust policy: ec2.amazonaws.com)
  └── wrapped by Instance Profile
        └── attached to Instance
              └── credentials delivered via IMDS
```

- The console creates the profile invisibly; CloudFormation and Terraform make you declare both
- Credentials arrive at `http://169.254.169.254/latest/meta-data/iam/security-credentials/<role>`
  and rotate automatically — **no keys on the instance**
- Changing the role propagates to running instances within minutes, no restart
- Whoever launches the instance needs **`iam:PassRole`** on the role

You need a role whenever *anything* on the instance calls an AWS API — including the
**SSM Agent** and **CloudWatch Agent**, not just your own code.

---

## 6. IMDS — instance metadata service

Link-local endpoint at `169.254.169.254`. Never leaves the instance, needs no routing,
works in a fully private subnet.

```bash
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -sH "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id
```

Useful paths: `instance-id`, `local-ipv4`, `public-ipv4`,
`placement/availability-zone`, `iam/security-credentials/<role>`, `/latest/user-data`.

> **IMDSv1 vs v2.** v1 was an unauthenticated GET, so any SSRF bug in a web app could read
> the instance's IAM credentials (this is the Capital One breach). v2 requires a PUT to get
> a session token first and sets a low IP TTL so responses can't be proxied off-box.
> Harden with `HttpTokens: required`.

---

## 7. Bootstrapping — user data

Script run at **first boot only**, as root, by cloud-init (Linux) or EC2Launch (Windows).

```yaml
UserData:
  Fn::Base64: |
    #!/bin/bash
    dnf install -y nginx
    systemctl enable --now nginx
```

- Base64-encoded, delivered via IMDS at `/latest/user-data`
- **16 KB limit** before encoding — larger payloads fetch a script from S3
- **Not secret.** Anyone who can reach IMDS reads it in plaintext. Never put credentials there.
- **EC2 does not know if it worked.** The instance reports `running` either way.
  Logs: `/var/log/cloud-init-output.log`
- In CloudFormation, `cfn-signal` makes the stack wait for bootstrapping to finish

**Bootstrapping vs AMI baking:** bootstrapping keeps AMIs generic but slows boot and depends
on package repos. Baking (Image Builder, Packer) boots fast and is reproducible but goes
stale. Most real setups do both.

---

## 8. AMIs

- **Regional.** Copy to another region to use it there.
- Backed by EBS snapshots — sharing an AMI means sharing the snapshots too
- Permissions are **account-level only**, never per-user:

| Setting                 | Who can launch                 |
|-------------------------|--------------------------------|
| Private (default)       | Owner account only             |
| Explicit share          | Specific account IDs           |
| Organization / OU share | Every account in the Org or OU |
| Public                  | Everyone                       |

Inside a shared account, **IAM** decides which identities may use it — the two-gate pattern.

Encrypted AMIs cannot be made public, and sharing one requires sharing the KMS key.

**`LatestAmiId` trick** — resolve the current AMI from an SSM public parameter instead of
hardcoding an ID that goes stale:

```yaml
Type: 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
Default: '/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64'
```

---

## 9. Placement groups

Control where instances sit physically. Free. Set at launch only.

| Type          | Placement                                         | Use for                                                       |
|---------------|---------------------------------------------------|---------------------------------------------------------------|
| **Cluster**   | Packed tight, one AZ, often one rack              | HPC, lowest latency, 10 Gbps single-flow                      |
| **Spread**    | Distinct hardware, **max 7 per AZ**               | A few critical instances that must not share a failure domain |
| **Partition** | Groups on separate racks, **7 partitions per AZ** | HDFS, Cassandra, Kafka — rack-aware distributed systems       |

Cluster trades blast radius for latency. Spread and partition do the opposite; partition
also **exposes the partition ID** so the software can place replicas deliberately.

---

## 10. Tenancy

| Model                  | Hardware                         | You control placement?              | Billing            |
|------------------------|----------------------------------|-------------------------------------|--------------------|
| **Shared** (default)   | Shared with other customers      | No                                  | Per instance       |
| **Dedicated Instance** | Not shared with other accounts   | No — you never see the host         | Per instance + fee |
| **Dedicated Host**     | A whole physical server is yours | **Yes** — sockets and cores visible | **Per host**       |

Dedicated Host exists mainly for **BYOL licensing** (Windows Server, SQL Server, Oracle are
licensed per socket/core, so you need visibility into the hardware). Exam tell:
"bring your own license" or "per-socket licensing" → Dedicated Host.

---

## 11. Purchase options

| Option                               | Discount   | Trade-off                                  |
|--------------------------------------|------------|--------------------------------------------|
| **On-Demand**                        | none       | Maximum flexibility                        |
| **Reserved Instance / Savings Plan** | up to ~72% | 1 or 3 year commitment                     |
| **Spot**                             | up to ~90% | **Can be reclaimed with 2 minutes notice** |
| **Dedicated Host**                   | —          | Licensing / compliance                     |

Spot fits fault-tolerant, interruptible, stateless work — batch, CI, big data. Never a
database or anything holding state on instance store.

---

## 12. Connecting

| Method                   | Needs                                                                                                   |
|--------------------------|---------------------------------------------------------------------------------------------------------|
| **SSH**                  | Key pair, port 22 open, public IP or bastion                                                            |
| **Session Manager**      | SSM Agent + `AmazonSSMManagedInstanceCore` role + a path to SSM endpoints. **No key, no inbound port.** |
| **EC2 Instance Connect** | Pushes a temporary key; still needs port 22                                                             |
| **Windows RDP**          | Decrypt the Administrator password with your **private key**, then RDP 3389                             |

Windows password retrieval:

```bash
aws ec2 get-password-data --instance-id i-0abc --priv-launch-key ~/.ssh/A4L.pem
```

Only works for the *initial* password, and not for ~4 minutes after launch.

Session Manager is the modern answer: the agent dials **out** over a WebSocket, so you need
zero inbound rules. Access is governed by IAM, so revoking someone is a policy change rather
than a key hunt. Its Windows equivalent is **Fleet Manager Remote Desktop**.

---

## 13. Scope cheat sheet

| Scope  | Objects                                        |
|--------|------------------------------------------------|
| Region | AMI, key pair, security group, placement group |
| **AZ** | **Instance, EBS volume, subnet**               |
| Global | none                                           |

The AZ row is what you must duplicate for high availability.

---

## 14. Gotchas checklist

- Public IP is **lost on stop/start** unless it's an Elastic IP.
- Instance store is **wiped on stop**, not just terminate.
- EBS volumes are **AZ-locked** — to move one, snapshot it and restore in the other AZ.
- Root volume is **deleted on terminate** by default; extra volumes usually are not.
- The instance OS never sees its public IP.
- User data runs **once**, and its failure is invisible to EC2.
- Roles are needed for the **SSM and CloudWatch agents**, not just your application code.
- `Placement.AvailabilityZone` and `SubnetId` both exist (EC2-Classic legacy) — the subnet
  determines the AZ, and a conflict is an error.
- Enable **IMDSv2** (`HttpTokens: required`) or an SSRF bug leaks your role credentials.
