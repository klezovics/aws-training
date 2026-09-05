# EFS
# EFS architecture
- Network based filesystem = can be mounted by multiple hosts
- EFS = implementation NFSv4
- EFS is mounted into Linux
- Private service which can be mounted onto mount targets inside a VPC
- Can be connected to on-prem via VPN or DX
- In VPC EFS is projected as mount targets, which have private IPs
- EC2 connects to mount targets

EXAM NOTES:
- EFS is for Linux only 
- Has general purpose and MAX I/O modes(smaller latency)
- General purpose is default for 99% use cases
- Bursting and Provisioned throughput modes
- Has standard and infrequent access storage tiers (can use lifecycle policies)

# AWS backup
- AWS Backup = fully managed data-protection (backup/restore) service
- Consolidates management of backups into one place accross accounts and regions
- Supports backups for a lot of AWS services RDS, DynamoDB, S3, etc

Domain model:
- Backup plan = frequence window, region copy, vault, lifecycle
- Resources -> what is being backed up ?
- Vaults -> backup destination
- Vault locks -> can someone delete a backup ??
- On-demand backup -> can trigger a backup on demand
- PITR -> can restore to a point in time in RDS