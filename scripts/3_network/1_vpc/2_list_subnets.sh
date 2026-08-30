#!/usr/bin/env bash
# Subnets, sorted by AZ, and whether each one is PUBLIC.
# "Public" is not a flag: it means the subnet's route table has 0.0.0.0/0 -> igw-*
set -euo pipefail
export AWS_PROFILE="${AWS_PROFILE:-ak-aws-training}"
export AWS_PAGER=""

echo "=== subnets in $(aws configure get region) ==="
aws ec2 describe-subnets \
  --query 'sort_by(Subnets,&AvailabilityZone)[].{
      Name:Tags[?Key==`Name`]|[0].Value,
      Id:SubnetId,
      VPC:VpcId,
      AZ:AvailabilityZone,
      CIDR:CidrBlock,
      FreeIPs:AvailableIpAddressCount,
      AutoPublicIP:MapPublicIpOnLaunch}' \
  --output table

echo "=== public or private? (resolved via the effective route table) ==="
for s in $(aws ec2 describe-subnets --query 'Subnets[].SubnetId' --output text); do
  vpc=$(aws ec2 describe-subnets --subnet-ids "$s" --query 'Subnets[0].VpcId' --output text)

  # explicit association first; fall back to the VPC's main route table
  rt=$(aws ec2 describe-route-tables \
        --filters "Name=association.subnet-id,Values=$s" \
        --query 'RouteTables[0].RouteTableId' --output text)
  if [[ "$rt" == "None" ]]; then
    rt=$(aws ec2 describe-route-tables \
          --filters "Name=vpc-id,Values=$vpc" "Name=association.main,Values=true" \
          --query 'RouteTables[0].RouteTableId' --output text)
    via="main"
  else
    via="explicit"
  fi

  igw=$(aws ec2 describe-route-tables --route-table-ids "$rt" \
        --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0`].GatewayId' --output text)

  case "$igw" in
    igw-*) verdict="PUBLIC  via $igw" ;;
    "")    verdict="private (no default route)" ;;
    *)     verdict="private (0.0.0.0/0 -> $igw)" ;;
  esac
  printf '  %-26s %-24s %-9s %s\n' "$s" "$rt" "($via)" "$verdict"
done

echo
echo "note: AWS reserves 5 IPs per subnet, so a /20 shows 4091 free, not 4096."
