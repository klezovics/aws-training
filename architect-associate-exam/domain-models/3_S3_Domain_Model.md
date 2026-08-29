# S3 Domain Model

S3 = a regional, public-zone key-value object store.
Global **namespace** (bucket names are unique worldwide), **regional service** (data lives in one region).


---

## 1. The shape

```
Account
  └── Bucket          globally unique name, ONE region, immutable region
        └── Object    key + value + metadata (+ versions)
```

**There are no folders.** S3 is flat. `photos/2026/cat.jpg` is one key that happens to
contain slashes. The console renders fake folders from key prefixes.

Consequences:

- You cannot rename or move a "folder" — you copy every object and delete the old keys
- No per-folder permissions — only **prefix patterns** in policies
- Listing is prefix-based

| Thing       | Notes                                                                                   |
|-------------|-----------------------------------------------------------------------------------------|
| **Bucket**  | Name globally unique. Region fixed at creation. Default quota 10,000 per account.       |
| **Object**  | Key (up to 1024 bytes), value (up to 5 TB), metadata, optional tags, optional versions. |
| **Version** | Only exists if versioning is on. Identified by version ID.                              |

---

## 2. The API is tiny

```
PutObject · GetObject · DeleteObject · ListObjectsV2
```

That is the whole data plane. Everything else in S3 is **bucket configuration**.

Two naming traps:

| Action                | What it does                      | CLI                |
|-----------------------|-----------------------------------|--------------------|
| `s3:ListAllMyBuckets` | Lists your **buckets**            | `aws s3 ls`        |
| `s3:ListBucket`       | Lists **objects inside** a bucket | `aws s3 ls s3://b` |

ARN shapes:

```
arn:aws:s3:::my-bucket      -> bucket-level actions (ListBucket)
arn:aws:s3:::my-bucket/*    -> object-level actions (GetObject, PutObject)
```

Using `/*` for `ListBucket` silently never matches.

---

## 3. Where config lives

| Level       | Settings                                                                                                                |
|-------------|-------------------------------------------------------------------------------------------------------------------------|
| **Account** | Block Public Access (account-wide), default encryption, Storage Lens                                                    |
| **Bucket**  | Policy, versioning, lifecycle, replication, encryption, logging, events, website hosting, Object Lock, Object Ownership |
| **Object**  | Storage class, metadata, tags, per-object KMS key, legal hold, ACL (legacy)                                             |

> **The bucket is the configuration unit.** Account level is guardrails; object level is
> mostly overrides of bucket defaults.

Design rule: **one bucket per distinct configuration need**, not one per app.
Different lifecycle rules, replication targets, or public access = different buckets.

---

## 4. Access control — four layers

| Layer                   | Scope            | Use for                                        |
|-------------------------|------------------|------------------------------------------------|
| **Block Public Access** | Account + bucket | Hard veto. Beats everything below.             |
| **Bucket policy**       | Bucket / prefix  | Anonymous access, cross-account, blanket rules |
| **Object ACL**          | Per object       | **Legacy.** Disabled by default since 2023.    |
| **Identity policy**     | The caller       | Identities in your own account                 |

**Evaluation:**

```
explicit Deny anywhere            -> DENIED
Block Public Access blocks it     -> DENIED (overrides bucket policy)
same account:  identity OR bucket policy allows -> ALLOWED
cross account: identity AND bucket policy allow -> ALLOWED
otherwise                         -> DENIED (implicit)
```

**Object Ownership: Bucket owner enforced** is the default for new buckets. It disables
ACLs entirely and makes the bucket owner own every object. Leave it on.

Two bucket-policy patterns worth memorising:

```json
"Condition": {"Bool": {"aws:SecureTransport": "false"}}          // with Deny -> force HTTPS
"Condition": {"StringEquals": {"aws:sourceVpce": "vpce-abc123"}} // only via your VPC endpoint
```

**Presigned URL** — a time-limited URL carrying *your* signature. Lets someone with no AWS
credentials GET or PUT one object. Cannot grant more than you have; dies when your
credentials do.

```bash
aws s3 presign s3://bucket/key --expires-in 3600
```

---

## 5. Versioning

With versioning on, **nothing is destroyed by a normal write or delete**:

| Operation   | Result                                                                        |
|-------------|-------------------------------------------------------------------------------|
| Overwrite   | New version; old one still fetchable by version ID                            |
| Delete      | Adds a **delete marker**. Object vanishes from listings, all versions remain. |
| True delete | Only by deleting a specific version ID (`s3:DeleteObjectVersion`)             |

- **One-way switch.** You can suspend it, but never return to "never versioned".
- Prerequisite for **replication** and **Object Lock**.
- **You pay for every version.** Versioning without lifecycle expiry is the classic bill shock.

**Object Lock** = WORM. Versions immutable for a retention period, unbreakable even by the
account root in compliance mode. Requires versioning.

---

## 6. Storage classes

Set **per object**, not per bucket. The bucket only supplies a default for new uploads.

| Class                          | Storage cost | Retrieval | Min duration | GetObject works?       |
|--------------------------------|--------------|-----------|--------------|------------------------|
| **Standard**                   | highest      | free      | none         | yes                    |
| **Intelligent-Tiering**        | auto         | free*     | none         | yes                    |
| **Standard-IA**                | lower        | per GB    | 30 days      | yes                    |
| **One Zone-IA**                | lower still  | per GB    | 30 days      | yes (single AZ!)       |
| **Glacier Instant Retrieval**  | low          | per GB    | 90 days      | **yes, ms**            |
| **Glacier Flexible Retrieval** | lower        | per GB    | 90 days      | **NO — restore first** |
| **Deep Archive**               | lowest       | per GB    | 180 days     | **NO — restore first** |

\* small per-object monitoring fee.

**Asking for an archived object:**

```
InvalidObjectState: The operation is not valid for the object's storage class
```

Restore creates a **temporary readable copy**; the object stays in Glacier:

```bash
aws s3api restore-object --bucket b --key k \
  --restore-request 'Days=7,GlacierJobParameters={Tier=Standard}'
```

Flexible: 1-5 min (Expedited) to 5-12 h (Bulk). Deep Archive: 12 h to 48 h.

> **Glacier Instant Retrieval is the only archive class where `GetObject` still works.**
> Deep Archive is unusable for anything a user might request interactively.

**One Zone-IA** stores in a single AZ — cheaper, but an AZ loss destroys the data.
Only for reproducible content.

---

## 7. Lifecycle rules

Bucket-level config that acts **per object**, by prefix or tag. The cost lever.

```json
{
  "Status": "Enabled",
  "Filter": {
    "Prefix": "logs/"
  },
  "Transitions": [
    {
      "Days": 30,
      "StorageClass": "STANDARD_IA"
    },
    {
      "Days": 90,
      "StorageClass": "GLACIER_IR"
    },
    {
      "Days": 365,
      "StorageClass": "DEEP_ARCHIVE"
    }
  ],
  "NoncurrentVersionExpiration": {
    "NoncurrentDays": 90
  },
  "Expiration": {
    "Days": 2555
  }
}
```

- Transitions happen **in place** — the key never changes, so nothing breaks.
  This is why you do NOT create a separate bucket per storage class.
- `NoncurrentVersionExpiration` is what stops versioning from growing without bound.
- Small per-object transition fee — for millions of tiny objects, check the arithmetic.

---

## 8. Encryption

| Mode                | Key managed by         | Notes                                                               |
|---------------------|------------------------|---------------------------------------------------------------------|
| **SSE-S3** (AES256) | AWS                    | Default on all new buckets. Free, invisible.                        |
| **SSE-KMS**         | You, via KMS           | Auditable in CloudTrail, per-key access control. Costs per request. |
| **SSE-C**           | You supply per request | AWS never stores the key. Rare.                                     |
| **Client-side**     | You, before upload     | AWS sees only ciphertext.                                           |

**KMS gotcha:** the KMS **key policy** must allow access. An IAM policy alone is never
enough unless the key policy delegates to IAM.

`ServerSideEncryption: AES256` in `head-object` output = SSE-S3.

---

## 9. Cost model — four meters

| Meter                 | Notes                                                              |
|-----------------------|--------------------------------------------------------------------|
| **Storage**           | Per GB-month, varies by class                                      |
| **Requests**          | Per 1,000 PUT/GET/LIST. **Cheaper classes cost MORE per request.** |
| **Data transfer out** | To internet. **In is free**, same-region to AWS services is free.  |
| **Retrieval**         | Glacier classes only, per GB                                       |

The exam trap: moving rarely-read but frequently-listed data to Glacier can cost **more**,
because request + retrieval charges exceed the storage saving. Minimum-duration charges
apply even if you delete early.

---

## 10. Object metadata

`head-object` returns:

| Field                  | Meaning                                                                                                                           |
|------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| `ContentLength`        | Size in bytes                                                                                                                     |
| `ETag`                 | Content fingerprint. **Single-part = MD5 of the object.** Multipart = MD5 of concatenated part MD5s + `-<n>`, NOT the file's MD5. |
| `StorageClass`         | Absent means STANDARD                                                                                                             |
| `ServerSideEncryption` | `AES256` = SSE-S3, `aws:kms` = SSE-KMS                                                                                            |
| `Restore`              | Present only for archived objects being restored                                                                                  |

ETag uses: integrity check, `If-None-Match` to skip unchanged downloads (304),
`If-Match` for optimistic concurrency.

Note: `aws s3 sync` compares **size + last-modified**, not ETags, by default.

---

## 11. The rest of the surface

| Feature                       | One-liner                                                                       |
|-------------------------------|---------------------------------------------------------------------------------|
| **Cross-Region Replication**  | Async copy to another region. Both buckets need versioning.                     |
| **Same-Region Replication**   | Same, within a region (compliance, log aggregation)                             |
| **Multi-Region Access Point** | One global hostname over several buckets                                        |
| **Transfer Acceleration**     | Upload via CloudFront edge, then AWS backbone. For distant clients.             |
| **Multipart upload**          | Required over 5 GB, recommended over 100 MB. Parallel parts.                    |
| **Event notifications**       | Object created/deleted -> Lambda, SQS, SNS, EventBridge                         |
| **Static website hosting**    | **HTTP only** — put CloudFront in front for HTTPS                               |
| **Access logging**            | Server access logs to another bucket                                            |
| **S3 Inventory**              | Scheduled CSV/Parquet report of all objects. Cheaper than listing huge buckets. |
| **Storage Lens**              | Account-wide usage and cost analytics                                           |
| **Object Lambda**             | Transform objects on the fly during GET                                         |

---

## 12. Gotchas checklist

- `s3:ListBucket` ≠ listing buckets. That is `s3:ListAllMyBuckets`.
- `arn:...:bucket` vs `arn:...:bucket/*` — bucket-level vs object-level.
- Block Public Access at the **account** level overrides every bucket policy.
- Versioning is one-way and **you pay for every version**.
- Gateway endpoints only reach **same-region** buckets.
- Static website endpoints are **HTTP only**.
- S3 accepts plain **HTTP** — deny `aws:SecureTransport: false` to force TLS.
- Deleting a bucket requires it to be **empty**, including all versions and delete markers.
- Bucket names are released on delete — someone else can claim them.
