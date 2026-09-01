# Purpose

This repo holds study notes for the AWS Certified Solutions Architect
Associate exam, following Adrian Cantrill's course:
https://learn.cantrill.io/courses/1820301/lectures/41301458

Notes live under `architect-associate-exam/`, one markdown file per
lecture/topic, with supporting images in `architect-associate-exam/img/`.

# AWS Guidance

- Prefer the AWS MCP Server for AWS interactions — it provides sandboxed
  execution, observability, and audit logging. If unavailable, use the
  AWS CLI directly.
- Before starting a task, check whether a relevant AWS skill is available.
  Load the skill with `retrieve_skill` and prefer its guidance over
  general knowledge.
- When uncertain about specific AWS details (API parameters, permissions,
  limits, error codes), verify against documentation rather than guessing.
  State uncertainty explicitly if you cannot confirm.
- When creating infrastructure, prefer infrastructure-as-code (AWS CDK or
  CloudFormation) over direct CLI commands.
- When working with infrastructure, follow AWS Well-Architected Framework
  principles.
- Do not use em dashes in AWS resource names or descriptions. Use
  hyphens instead.

## Secret Safety

- MUST load the `aws-secrets-manager` skill first for any secret,
  credential, API key, token, or password task. MUST NOT call
  `secretsmanager get-secret-value` or `batch-get-secret-value`, and MUST
  NOT hit the Secrets Manager Agent daemon directly. MUST use
  `{{resolve:secretsmanager:secret-id:SecretString:json-key}}` with
  `asm-exec` so the secret resolves at runtime without entering context.

# Service understanding notes

Yep — this was the AWS service description template we aligned on:
This is called service matrix

Essence of the service — what it fundamentally does
Global or regional — scope and where it lives
Main logical resources — the key entities/resources you create
Main API operations — important create/read/update/delete/use actions
Common use cases — when you actually use it
Important features/configuration — major knobs, modes, capabilities
Security — IAM, encryption, access control, network/security considerations
Cost model — what you pay for
Integrations — important AWS services it connects with
Constraints/limits -> important constraints and limits