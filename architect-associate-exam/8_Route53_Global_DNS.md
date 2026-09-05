# Route53
# Public hosted zones
- Anyone on the internet can resolve domain names from it

# Private hosted zones
- Only VPC associated with it can resolve domain names from it

# CNAME vs R53 alias
- CNAME:  client asks api.example.com  → gets "my-alb.elb.amazonaws.com" → client must ask AGAIN for that name
- Alias:  client asks api.example.com  → Route 53 internally looks up the ALB's current IPs → returns 3.120.45.67 directly

- Alias is a type A record, but with an AliasTarget instead of a value
```json
  {
  "Name": "api.aktraining.click.",
  "Type": "A",
  "AliasTarget": {
    "HostedZoneId": "ZLY8HYME6SFDD",
    "DNSName": "d-05ta3celbl.execute-api.eu-central-1.amazonaws.com.",
    "EvaluateTargetHealth": false
  }
}
```

Compare this to a simple A record
```json
{
  "Name": "x.example.com.",
  "Type": "A",
  "TTL": 300,
  "ResourceRecords": [
    {
      "Value": "3.120.45.67"
    }
  ]
}
```
# R53 health checks

# Routing policies
- For a given record set you can give R53 different routing policies and it will execute them

## Simple routing
## Failover routing
## Multi-value routing
## Weighted routing
## Latency routing
## Geolocation routing
## Geoproximity routing
## R53 interoperability
## DNSSEC using route53