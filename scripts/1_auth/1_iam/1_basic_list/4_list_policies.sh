#!/usr/bin/env bash
# Customer managed policies only (--scope Local). The default scope also returns
# ~1000 AWS managed policies, which is never what you want.
set -euo pipefail
export AWS_PROFILE="${AWS_PROFILE:-ak-aws-training}"
export AWS_PAGER=""

echo "=== customer managed policies ==="
aws iam list-policies --scope Local \
  --query 'Policies[].[PolicyName,AttachmentCount,DefaultVersionId,CreateDate]' \
  --output table

echo "=== policy documents ==="
for arn in $(aws iam list-policies --scope Local --query 'Policies[].Arn' --output text); do
  ver=$(aws iam get-policy --policy-arn "$arn" --query 'Policy.DefaultVersionId' --output text)
  echo "--- $arn ($ver)"
  aws iam get-policy-version --policy-arn "$arn" --version-id "$ver" \
    --query 'PolicyVersion.Document' --output json
done
