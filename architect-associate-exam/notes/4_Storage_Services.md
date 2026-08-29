# Storage service overview

Service:
S3 -> file store. Main way in/out of AWS.


# Storage Service Details

# S3 
- S3 = K:V store. String -> Byte blob
- S3 = Global service. Buckets are regional.

- S3 simple structure. S3 > Bucket list > Objects in each bucket
- So therefore you have only 3 places to apply config: S3 level, Bucket level, Object level
- Bucket is the main configuration unit. 
- So you mostly create/configure a bucket and then just read/write objects to it 