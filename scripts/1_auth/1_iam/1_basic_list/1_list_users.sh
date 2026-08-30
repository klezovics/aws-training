#!/usr/bin/env bash
# IAM users in this account, with the groups each one belongs to.
set -euo pipefail
export AWS_PROFILE="${AWS_PROFILE:-ak-aws-training}"
export AWS_PAGER=""

echo "=== IAM users ==="
aws iam list-users \
  --query 'Users[].[UserName,UserId,CreateDate,PasswordLastUsed]' \
  --output table

echo "=== group membership per user ==="
for u in $(aws iam list-users --query 'Users[].UserName' --output text); do
  groups=$(aws iam list-groups-for-user --user-name "$u" --query 'Groups[].GroupName' --output text)
  printf '  %-24s %s\n' "$u" "${groups:-<none>}"
done
