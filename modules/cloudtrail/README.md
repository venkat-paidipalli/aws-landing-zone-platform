# CloudTrail Module

## Status

**Implemented** — creates an account-level CloudTrail trail for management
event auditing with S3 delivery.

## Purpose

Deploys an account-level CloudTrail baseline:

- Captures management API events across all regions
- Delivers audit logs to a pre-existing S3 bucket
- Validates log file integrity
- Includes global service events (IAM, STS)

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_cloudtrail.this` | CloudTrail trail with event selector |

## Secure Defaults

| Setting | Default | Rationale |
|---------|---------|-----------|
| `is_multi_region_trail` | `true` | Captures events in all regions for complete visibility |
| `include_global_service_events` | `true` | IAM/STS events are critical for security monitoring |
| `enable_log_file_validation` | `true` | Detects log tampering via digest files |
| `enable_logging` | `true` | Trail actively records (can pause without destroy) |
| `is_organization_trail` | `false` | Account-level only; org trail is separate scope |
| `management_event_read_write_type` | `"All"` | Captures both read and write management events |

## Management Events

Management events are the baseline — always captured:
- API calls that create, modify, or delete AWS resources (write)
- API calls that list or describe AWS resources (read)
- Console sign-in events

Default captures `All` (read + write). Can be restricted to `ReadOnly` or
`WriteOnly` for specific use cases.

## Data Events

Data events (S3 object operations, Lambda invocations) are **NOT** enabled
by default:
- High volume → significantly higher cost
- Require explicit opt-in per use case
- Not needed for baseline security auditing

Data event support can be added via additional event selectors in future
iterations.

## CloudWatch Logs

CloudWatch Logs integration is **NOT** configured in this module:
- S3 is the durable audit destination
- CloudWatch Logs adds cost and complexity
- Real-time alerting is a separate operational concern
- Can be added as a future enhancement

## Organization Trail

Organization trails (`is_organization_trail = true`) are **NOT** the default:
- Requires AWS Organizations trusted access
- Requires execution from the management account
- More complex setup and permissions
- Will be designed separately when the management account composition exists

The variable is exposed with `default = false` so the option is visible but
safe.

## Dependencies

| Dependency | Required | Provided By |
|-----------|----------|-------------|
| S3 bucket with CloudTrail policy | Yes | `modules/log-archive` |
| KMS key (optional) | No | Caller provides |
| SNS topic (optional) | No | Caller provides |

This module does NOT create the S3 bucket. Use the `log-archive` module
(or equivalent) to create the bucket with appropriate policy.

## Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `trail_name` | `string` | Yes | — | Trail name (3-128 chars) |
| `s3_bucket_name` | `string` | Yes | — | Delivery bucket (must exist) |
| `s3_key_prefix` | `string` | No | `""` | Optional S3 prefix |
| `is_multi_region_trail` | `bool` | No | `true` | All-region capture |
| `include_global_service_events` | `bool` | No | `true` | IAM/STS events |
| `enable_log_file_validation` | `bool` | No | `true` | Tamper detection |
| `enable_logging` | `bool` | No | `true` | Active logging |
| `is_organization_trail` | `bool` | No | `false` | Org-wide trail |
| `sns_topic_name` | `string` | No | `""` | Optional SNS topic |
| `kms_key_id` | `string` | No | `""` | Optional KMS key ARN |
| `management_event_read_write_type` | `string` | No | `"All"` | All/ReadOnly/WriteOnly |
| `tags` | `map(string)` | No | `{}` | Tags (no aws: prefix) |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `trail_id` | `string` | Trail ID |
| `trail_arn` | `string` | Trail ARN |
| `trail_name` | `string` | Trail name |
| `trail_home_region` | `string` | Home region |
| `multi_region_enabled` | `bool` | Multi-region status |
| `log_file_validation_enabled` | `bool` | Validation status |
| `cloudtrail_metadata` | `object` | Summary configuration |

## Limitations

- One management trail per account is typical (AWS allows multiple but adds cost)
- Does not create S3 bucket (caller provides via log-archive module)
- Does not create CloudWatch Logs group/role
- Does not configure data events (opt-in for future)
- Organization trail requires separate setup
- Cannot verify S3 bucket policy at plan time

## Example Usage

```hcl
module "cloudtrail" {
  source = "../../modules/cloudtrail"

  trail_name     = "lz-account-trail"
  s3_bucket_name = module.log_archive.bucket_name
  s3_key_prefix  = "cloudtrail"

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }
}
```
