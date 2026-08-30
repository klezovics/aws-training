#!/usr/bin/env bash
# IAM roles. Service-linked roles (AWSServiceRoleFor*) are hidden by default -
# there are dozens and AWS manages them; pass -a to show everything.
set -euo pipefail
export AWS_PROFILE="${AWS_PROFILE:-ak-aws-training}"
export AWS_PAGER=""

FILTER='Roles[?!starts_with(RoleName, `AWSServiceRoleFor`)]'
[[ "${1:-}" == "-a" ]] && FILTER='Roles[]'

echo "=== IAM roles ${1:-} ==="
aws iam list-roles --query "$FILTER.[RoleName,MaxSessionDuration,CreateDate]" --output table

echo "=== who can assume them (the trust policy Principal) ==="
for r in $(aws iam list-roles --query "$FILTER.RoleName" --output text); do
  trust=$(aws iam get-role --role-name "$r" \
    --query 'Role.AssumeRolePolicyDocument.Statement[].Principal' --output json | tr -d '\n ')
  printf '  %-44s %s\n' "$r" "$trust"
done
