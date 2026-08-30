# Storage service overview

Service:
S3 -> file store. Main way in/out of AWS.
RDS/Aurora -> relational 
EBS/EFS -> these are for EC2 instances.
ElastiCache -> caches liek Redis or Memcached
DynamoDB -> NoSQL K:V store for massive scale simple data access patterns

# Key facts
There are these main storage paradigms:
- Object storage -> S3
- File/block storage -> EBS/EFS/Ephemeral storage
- Database storage -> Dividens into SQL (RDS) and NoSQL(various formats)
- Caches -> ElastiCache
- Managed storage apps -> MSK

# Storage Service Details

# S3 
- S3 = K:V store. String -> Byte blob
- S3 = Global service. Buckets are regional.

- S3 simple structure. S3 > Bucket list > Objects in each bucket
- So therefore you have only 3 places to apply config: S3 level, Bucket level, Object level
- Bucket is the main configuration unit. 
- So you mostly create/configure a bucket and then just read/write objects to it 