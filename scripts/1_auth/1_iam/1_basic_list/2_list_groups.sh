#!/usr/bin/env bash
# IAM groups, their members, and the policies attached to each group.
set -euo pipefail
export AWS_PROFILE="${AWS_PROFILE:-ak-aws-training}"
export AWS_PAGER=""

echo "=== IAM groups ==="
aws iam list-groups --query 'Groups[].[GroupName,GroupId,CreateDate]' --output table

for g in $(aws iam list-groups --query 'Groups[].GroupName' --output text); do
  echo "--- $g"
  echo "    members:  $(aws iam get-group --group-name "$g" --query 'Users[].UserName' --output text)"
  echo "    managed:  $(aws iam list-attached-group-policies --group-name "$g" --query 'AttachedPolicies[].PolicyName' --output text)"
  echo "    inline:   $(aws iam list-group-policies --group-name "$g" --query 'PolicyNames' --output text)"
done
