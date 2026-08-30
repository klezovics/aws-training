#!/usr/bin/env bash
# VPCs in the current region, plus what each one is attached to.
set -euo pipefail
export AWS_PROFILE="${AWS_PROFILE:-ak-aws-training}"
export AWS_PAGER=""

echo "=== VPCs in $(aws configure get region) ==="
aws ec2 describe-vpcs \
  --query 'Vpcs[].{
      Name:Tags[?Key==`Name`]|[0].Value,
      Id:VpcId,
      CIDR:CidrBlock,
      Default:IsDefault,
      State:State,
      DHCP:DhcpOptionsId}' \
  --output table

echo "=== internet gateways ==="
aws ec2 describe-internet-gateways \
  --query 'InternetGateways[].{Id:InternetGatewayId,AttachedTo:Attachments[0].VpcId,State:Attachments[0].State}' \
  --output table

echo "=== NAT gateways (these cost money) ==="
aws ec2 describe-nat-gateways \
  --query 'NatGateways[].{Id:NatGatewayId,VPC:VpcId,Subnet:SubnetId,State:State,IP:NatGatewayAddresses[0].PublicIp}' \
  --output table

echo "=== route tables: where can traffic go ==="
for rt in $(aws ec2 describe-route-tables --query 'RouteTables[].RouteTableId' --output text); do
  main=$(aws ec2 describe-route-tables --route-table-ids "$rt" --query 'RouteTables[0].Associations[0].Main' --output text)
  subs=$(aws ec2 describe-route-tables --route-table-ids "$rt" --query 'RouteTables[0].Associations[].SubnetId' --output text)
  echo "--- $rt  (main=$main  subnets=${subs:-<none, inherits main>})"
  aws ec2 describe-route-tables --route-table-ids "$rt" \
    --query 'RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId,NatGatewayId,TransitGatewayId,VpcPeeringConnectionId,State]' \
    --output text | sed 's/^/      /'
done
