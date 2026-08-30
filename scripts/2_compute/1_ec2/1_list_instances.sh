#!/usr/bin/env bash
# EC2 instances in the current region.
# By default only RUNNING ones; pass -a to include stopped/terminated.
set -euo pipefail
export AWS_PROFILE="${AWS_PROFILE:-ak-aws-training}"
export AWS_PAGER=""

FILTERS=(--filters "Name=instance-state-name,Values=running")
[[ "${1:-}" == "-a" ]] && FILTERS=()

echo "=== EC2 instances in $(aws configure get region) ${1:-} ==="
aws ec2 describe-instances ${FILTERS[@]+"${FILTERS[@]}"} \
  --query 'Reservations[].Instances[].{
      Name:Tags[?Key==`Name`]|[0].Value,
      Id:InstanceId,
      Type:InstanceType,
      State:State.Name,
      AZ:Placement.AvailabilityZone,
      Private:PrivateIpAddress,
      Public:PublicIpAddress,
      Launched:LaunchTime}' \
  --output table

echo
echo "=== count by state ==="
aws ec2 describe-instances \
  --query 'Reservations[].Instances[].State.Name' --output text \
  | tr '\t' '\n' | sort | uniq -c | sed 's/^/  /'
