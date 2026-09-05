# EC2 Advanced

# EC2 Bootstrapping
- User data -> its this boot script
- Can run a script on boot. Run only once on the first initial launch
- User Data - accessed via meta-data IP
- No EC2-side validation
- Make sure not to mess up the instance and avoid a bad config
- It is NOT secure. Don't store secrets there.
- You can edit it after when instance is stopped, but won't be run
- You run this script or AMI-bake it. If AMI-bake then faster, but less flexible
- AMI bake basically only install steps, which take a long time
- Need to optimize Boot-Time-To-Serice-Time

# Better Bootstrapping with CFN-INIT
- CFN-INIT is a way to pass powerful bootstrapping instructions into an EC2 instance
- This of it as a configuration management system
- User data (procedural) vs Desired State (cnf-init)
- You call from user data a cnf-init script which gets stuff to run from CNF template
- You can also make it send a signal (CreationPolicy waits for) to notify that everything is OK

# EC2 Instance Roles and Profile
- InstanceProfile = wrapper around IAM Role
- Temp credentials are delivered via instance meta-data (auto-renew)
- Always prefer to use roles as creds

# SSM Parameter Store
- Public service. Access requires IAM perms.
- SSM Param Store useful config values = configs + secrets
- SSM Param Store = Key-Value store. Keys have same struct as keys in S3
- Create params there and consume via AWS SDK
- Can also encrypt some values with a given KMS key

- Many AWS services integrate with this
- Param types = String, StringList, SecureString -> Plaintext and Ciphertext
- Param org = Hierarchies and Versioning -> /wordpress/myPassword -> this is hierarchies (permission can be given by subpath)
- There is also Public Parameters -> Latest AMI per region and similar
- Events can be triggered on changes

# System and app logging on EC2
- Sometimes you need to look deeper inside EC2 instane -> CloudWatch
- CloudWatch and CloudWatchLogs cannot see inside EC2
- Agent needs configs and permissions to work -> AgentConfig file + IAM role for EC2 instance with relevant permissions
- At scale use CFN to inject agent info or Param Store

# EC2 Placement Groups
EXAM NOTES: Very important for exam. Understand this well.

Placement groups -> determines which hosts EC2 instances are placed on
- Cluster -> pack close together (same rack, mostly same host, one AZ for sure) -> PERFORMANCE
- Cluster placement group -> can span VPC peers, but negative perf. 
- Cluster -> can give 10Gbp/s network speed, over 5Gb/s over normal ones. Supported by not all instance types
- Cluster -> ideally should all launch at the same time (very recommended)
- Cluster -> HPC, Scientific computing

- Spread -> different hosts -> Resilient. Can span multi-AZ. In AZ goes to diff racks. 7 instances per AZ limit.
- Spread -> infrastructure isolation. Not supported for dedicated instances or hosts.
- Spread -> UC is small number of critical instances that need to be isolated from each other.


- Partitions -> groups spread appart -> Topology awareness
- Partitions -> similar to spread. But have more than 7 instances per AZ.
- Partitions -> you get max 7 partitions per AZ. Each partition is isolated.
- Paritions -> Cassandra, Kafka. Topology aware apps can make use of this.
- Partitions -> instances are placed in a parition manually or EC2 choses

# Dedicated Hosts
- You get a full private host on which you can run your EC2 instances. No workloads from other users
- Host is for specific family of instances. You don't pay for running
- A lot of payment options
- Has FIXED numbers physical sockets and cores -> good for licensing (KEY FEATURE)
- There are AMI limits - no RHEL, SUSE, Windows AMIs
- No amazon RDS on it
- Placement groups are not supported
- Can be shared with other accounts in org using RAM(Resource access manager)

# Enchanced Networking & EBS Optimized
- This EC2 optimisations

## Enhanced Networking
- Uses SR-IOV -> NIC is virtualisation aware.
- Host has N logical cards on the real NIC and instances get access to them and this makes stuff fast
- Higher I/O and Lower Host CPU usage -> better networking speed. Higher packets-per-second. Consisten lower latency
- Turned on by default or can enable free of charge

## Enchanced storage
- EBS optimized is either ON/OFF on an instance
- Historically network was shared for network and EBS Ops -> slower
- EBS optimized = dedicated networking capacity for EBS
- Mostly its supported and enabled by default now