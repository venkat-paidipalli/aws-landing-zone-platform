# Log Archive Module

## Status

**Implemented** — creates a secure S3 bucket for audit and security log storage.

## Purpose

Provides durable, protected storage for security logs:

- Secure S3 bucket with complete public access block
- Versioning for tamper protection
- Server-side encryption (AES256 or KMS)
- Lifecycle rules for cost-effective retention
- Bucket policy for CloudTrail delivery
- Deny unencrypted transport

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_s3_bucket.this` | The log archive bucket |
| `aws_s3_bucket_ownership_controls.this` | BucketOwnerEnforced (no ACLs) |
| `aws_s3_bucket_public_access_block.this` | Complete public access lockdown |
| `aws_s3_bucket_versioning.this` | Versioning configuration |
| `aws_s3_bucket_server_side_encryption_configuration.this` | Encryption |
| `aws_s3_bucket_lifecycle_configuration.this` | Retention lifecycle |
| `aws_s3_bucket_policy.this` | CloudTrail delivery + TLS enforcement |

## Security Design

### Public Access

All four public access block settings enabled:
- `block_public_acls = true`
- `block_public_policy = true`
- `ignore_public_acls = true`
- `restrict_public_buckets = true`

### Versioning

Enabled by default. Prevents overwrite or deletion of log files without
creating new versions. Critical for audit integrity.

### Encryption

| Mode | Default | Description |
|------|---------|-------------|
| `AES256` | Yes | S3-managed encryption, zero configuration |
| `aws:kms` | No | Customer-managed KMS key (caller provides ARN) |

### Transport Security

Bucket policy includes a `DenyInsecureTransport` statement that denies all
requests made without TLS (`aws:SecureTransport = false`).

### Ownership Model

Uses `BucketOwnerEnforced` — disables legacy ACLs entirely. All objects
are owned by the bucket owner regardless of who uploaded them.

### Deletion Safety

- `force_destroy = false` by default
- Terraform cannot destroy a bucket with objects unless `force_destroy = true`
- Audit logs should survive accidental `terraform destroy`

## Lifecycle/Retention

| Phase | Default Days | Storage Class |
|-------|-------------|---------------|
| Hot | 0-89 | STANDARD |
| Warm | 90-364 | STANDARD_IA |
| Cold | 365-2554 | GLACIER |
| Expired | 2555 (7 years) | Deleted |

All transitions are configurable. Set to 0 to disable a phase.

## Bucket Policy

Grants CloudTrail service principal:
- `s3:GetBucketAcl` on the bucket (required for trail validation)
- `s3:PutObject` on `AWSLogs/*` prefix with `bucket-owner-full-control`

The policy uses `Principal: { Service: "cloudtrail.amazonaws.com" }` — not a
wildcard principal. The `DenyInsecureTransport` statement uses `Principal: "*"`
with a `Condition` that restricts to non-TLS requests only.

## Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `bucket_name` | `string` | Yes | — | S3 bucket name (valid format) |
| `enable_versioning` | `bool` | No | `true` | Enable bucket versioning |
| `encryption_type` | `string` | No | `"AES256"` | AES256 or aws:kms |
| `kms_key_arn` | `string` | No | `""` | KMS key ARN (required for aws:kms) |
| `force_destroy` | `bool` | No | `false` | Allow destroy with objects |
| `transition_to_ia_days` | `number` | No | `90` | Days to IA (0=disable) |
| `transition_to_glacier_days` | `number` | No | `365` | Days to Glacier (0=disable) |
| `expiration_days` | `number` | No | `2555` | Days to expire (0=disable) |
| `cloudtrail_account_ids` | `list(string)` | No | `[]` | Account IDs for delivery |
| `organization_id` | `string` | No | `""` | Org ID for policy conditions |
| `tags` | `map(string)` | No | `{}` | Tags (no aws: prefix) |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `bucket_id` | `string` | Bucket ID |
| `bucket_arn` | `string` | Bucket ARN |
| `bucket_name` | `string` | Bucket name |
| `encryption_type` | `string` | Encryption algorithm |
| `versioning_enabled` | `bool` | Versioning status |
| `log_archive_metadata` | `object` | Summary configuration |

## Limitations

- Does not create KMS keys (caller provides)
- Does not create CloudTrail or Config (separate modules)
- Does not configure S3 access logging for this bucket itself
- Lifecycle validation of day ordering done at plan time conceptually
  but Terraform cannot cross-validate separate variables in all cases
- Single bucket per module call (call multiple times for multiple buckets)

## Example Usage

```hcl
module "log_archive" {
  source = "../../modules/log-archive"

  bucket_name    = "lz-audit-logs-555500001111"
  encryption_type = "AES256"

  transition_to_ia_days      = 90
  transition_to_glacier_days = 365
  expiration_days            = 2555  # 7 years

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }
}
```
