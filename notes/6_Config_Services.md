# Config service list

Config, secrets, and the encryption layer they depend on.

- SSM Parameter Store -> THE fundamental config store. Free (standard tier).
- Secrets Manager     -> Parameter Store + automatic ROTATION. ~$0.40/secret/month.
- KMS                 -> key management. Everything else encrypts THROUGH it.
- AppConfig           -> feature flags + validated config rollouts (part of Systems Manager)
- CloudHSM            -> single-tenant dedicated hardware. Compliance only.

## Parameter Store
- Hierarchical K:V. Key is a path: /prod/db/host
- Types: String, StringList, SecureString (KMS-encrypted)
- `GetParametersByPath --recursive` reads a whole subtree
- Standard tier: free, 4KB values, 10,000 params. Advanced: paid, 8KB, 100,000.
- AWS publishes PUBLIC parameters, e.g. the latest AMI id:
  /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
- Less well known than Secrets Manager only because it is buried inside Systems Manager

## Secrets Manager
- Same shape as Parameter Store, but buys you the ROTATION state machine:
  createSecret -> setSecret -> testSecret -> finishSecret, run by a Lambda
- Secrets Manager DRIVES it (owns the schedule + versions). The Lambda just knows how
  to talk to the DB.
- Version stages: AWSCURRENT / AWSPENDING / AWSPREVIOUS. Your app always reads AWSCURRENT.
- Native RDS integration, cross-region replication
- delete-secret has a MINIMUM 7-day recovery window (unless --force-delete-without-recovery)

Rule of thumb: non-secret config and non-rotating secrets -> Parameter Store (free).
Must rotate (DB passwords, third-party keys) -> Secrets Manager.

## KMS
- Manages KEYS, not encryption. Services do the encrypting.
- Envelope encryption: KMS issues a DATA KEY, the service encrypts with it, KMS never
  sees your data. Hence the 4KB limit on direct Encrypt calls.
- KEY POLICY is mandatory. An IAM policy alone is NEVER enough unless the key policy
  delegates to IAM ("Enable IAM User Permissions"). This is the classic KMS AccessDenied.
- AWS-managed keys (aws/s3) = free, no policy control, no rotation control
  Customer-managed keys = ~$1/month, full policy control, rotation settings, grants
- Keys are REGIONAL. Cross-region replication needs a key in each region.

## Consuming config
- EC2       -> instance role + SDK, or fetch in user data
- ECS/Fargate -> task definition `secrets` block with valueFrom:
                 arn:aws:ssm:...:parameter/...      (Parameter Store)
                 arn:aws:secretsmanager:...:secret:...:key::  (JSON key extraction)
                 Permission goes on the TASK EXECUTION ROLE, not the task role.
- Lambda    -> env vars, or SDK call, or the Parameters and Secrets extension
- CloudFormation -> resolve at deploy/runtime without the value entering the template:
                 {{resolve:secretsmanager:secret-id:SecretString:json-key}}
                 {{resolve:ssm:/path/to/param}}

## Exam notes
- "Store config cheaply" -> Parameter Store
- "Automatic rotation"   -> Secrets Manager
- "Customer-managed encryption keys / audit key usage" -> KMS CMK
- "Single-tenant hardware / FIPS 140-2 Level 3" -> CloudHSM
- Fargate in a private subnet needs a NAT gateway or interface endpoints for
  ssm / secretsmanager / kms, or the task fails to start with ResourceInitializationError.
