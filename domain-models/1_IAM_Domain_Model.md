# IAM Domain Model

## IDENTITIES (principals)
- **User** — human or app. Thin object; can hold long-term credentials. ID prefix `AIDA`.
- **Group** — container of users. ID prefix `AGPA`.
  - NOT a principal: cannot be assumed, cannot appear as `Principal` in a resource policy.
  - Cannot nest. A user can be in 10 groups.
- **Role** — assumable identity, no long-term credentials. ID prefix `AROA`.
  - Has TWO policies doing different jobs:
    - trust policy    -> WHO may assume me (this is a resource policy)
    - identity policy -> WHAT I may do

## POLICIES THAT GRANT
- **Identity policy** — attached to user / group / role. No `Principal` field.
  - managed = own ARN, reusable across identities, versioned (5 versions), max 10 per identity
  - inline  = embedded in one identity, dies with it, not reusable
- **Resource policy** — attached to the resource. `Principal` field REQUIRED.
  - Only some services have them: S3, KMS, SQS, SNS, Lambda, Secrets Manager, ECR,
    API Gateway, EFS, CloudWatch Logs, OpenSearch, EventBridge, and role trust policies.
  - No resource policy: EC2, DynamoDB, RDS, EBS, CloudFront -> share a ROLE instead.

## POLICIES THAT LIMIT (never grant)
- **Permission boundary** — ceiling on what an identity policy can grant to one identity
- **SCP** — ceiling for a whole account / OU (Organizations). Hits the root user too.
- **Session policy** — ceiling passed at AssumeRole time, for that session only

## CREDENTIALS
- **Access key** — long-term, USERS ONLY, prefix `AKIA`. 0/1/2 per user (2 for rotation).
- **Login profile** — console password
- **MFA device** — virtual / hardware / passkey
- **STS credentials** — temporary, prefix `ASIA`.
  Three fields used together: AccessKeyId + SecretAccessKey + **SessionToken**.
  Not a JWT. Requests are SIGNED (SigV4 HMAC), not bearer-token authenticated.

## BRIDGES
- **Instance profile** — wraps exactly ONE role so EC2 can use it. Prefix `AIPA`.
  Console hides it; CFN/TF make you declare it.
- **Identity provider** — SAML 2.0 or OIDC registered in the account.
  Lets external identities call `AssumeRoleWithSAML` / `AssumeRoleWithWebIdentity`.
- **Assumed-role session** — the ACTUAL principal at request time:
  `arn:aws:sts::123:assumed-role/AppRole/i-0abc123`
  The session name is why CloudTrail and `aws:userid` show the instance id.

## PATH (all IAM entity types)
- Prefix inserted into the ARN: `arn:aws:iam::123:role/ec2-workloads/blue/AppRole`
- NOT part of the name; names still unique account-wide
- Immutable, set at creation, NOT exposed in the console (CLI/API/IaC only)
- Only purpose: give policies a prefix to wildcard on
- Used for delegated IAM admin, paired with a permission boundary

## EVALUATION ORDER
```
explicit Deny anywhere?              -> DENIED
SCP denies / does not allow?         -> DENIED
permission boundary does not allow?  -> DENIED
session policy does not allow?       -> DENIED
same account:  identity OR resource allows  -> ALLOWED
cross account: identity AND resource allow  -> ALLOWED
otherwise (implicit deny)            -> DENIED
```
Exceptions:
- **KMS**: key policy must allow. IAM alone is never enough unless the key policy
  delegates to IAM (the "Enable IAM User Permissions" statement).
- **S3 Block Public Access**: overrides bucket policies entirely.

## POLICY DOCUMENT SHAPE
- Policy = list of **Statements**. Each statement has exactly ONE `Effect`.
- Statement = Effect + Action + Resource + optional Condition (+ Principal in resource policies)
- `Sid` = optional label, ignored by evaluation, must be unique in the policy
- `Action` / `Resource` take a single value or a list; `Effect` never does

## KEY CONDITION KEYS
- `aws:PrincipalArn`, `aws:userid`, `aws:PrincipalOrgID`
- `aws:RequestedRegion` — pin an org to one region (exclude global services via NotAction)
- `aws:SecureTransport` — force HTTPS
- `aws:sourceVpce` / `aws:SourceVpc` — restrict to your VPC endpoint
- `ec2:SourceInstanceARN`, `aws:Ec2InstanceSourceVpc`, `aws:Ec2InstanceSourcePrivateIPv4`
  -> defend against credentials stolen off IMDS and used elsewhere
- `iam:PassedToService` — restrict which service a role may be passed to
- `iam:PermissionsBoundary` — require a boundary when creating roles (delegated admin)

## NOTE
`iam:PassRole` is a PERMISSION, not an API call. Checked whenever you hand a role to a
service (RunInstances, CreateFunction, RegisterTaskDefinition). It lives in the identity
policy of WHOEVER IS LAUNCHING, not on the role. Both it and the role's trust policy
must allow the operation.
