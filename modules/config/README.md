# Config Module

## Status

**Implemented** — creates an AWS Config governance baseline with recorder,
delivery channel, and managed compliance rules.

## Purpose

Deploys a per-account AWS Config baseline that:

- Records resource configuration changes
- Delivers configuration snapshots to S3
- Evaluates compliance via AWS-managed Config rules
- Provides **detective governance** (observe and report, never remediate)

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_config_configuration_recorder.this` | Defines what to record |
| `aws_config_delivery_channel.this` | Where to send data (S3, optional SNS) |
| `aws_config_configuration_recorder_status.this` | Enables recording |
| `aws_config_config_rule.managed` | AWS-managed compliance rules |

## Recorder Behavior

The recorder supports two modes:

| Mode | Setting | Behavior |
|------|---------|----------|
| All resources | `recording_all_resources = true` (default) | Records every supported resource type |
| Selected resources | `recording_all_resources = false` | Records only `selected_resource_types` |

Global resource types (IAM users, roles, policies) are included by default
(`include_global_resource_types = true`). In multi-region deployments, set
this to `true` in only one region to avoid duplicate recordings.

## Delivery Channel Dependency

This module does **NOT** create the S3 bucket or SNS topic. The caller must
provide pre-existing resources:

| Dependency | Variable | Required |
|-----------|----------|----------|
| S3 bucket | `delivery_s3_bucket` | Yes |
| S3 key prefix | `delivery_s3_key_prefix` | No |
| SNS topic | `delivery_sns_topic_arn` | No |
| IAM role | `recorder_role_arn` | Yes |

The S3 bucket and IAM role are typically created by a centralized logging
or baseline module in the log-archive or security account.

## Managed Config Rules

Rules use AWS-managed source identifiers. They evaluate compliance but
perform **no automatic remediation**.

### Baseline Rule Library

| Rule | Source Identifier | Purpose |
|------|-------------------|---------|
| S3 public access | `S3_BUCKET_PUBLIC_READ_PROHIBITED` | Detect public S3 buckets |
| Encrypted volumes | `ENCRYPTED_VOLUMES` | Detect unencrypted EBS volumes |
| Root MFA | `ROOT_ACCOUNT_MFA_ENABLED` | Detect root accounts without MFA |
| IAM password policy | `IAM_PASSWORD_POLICY` | Validate IAM password policy strength |
| CloudTrail enabled | `CLOUD_TRAIL_ENABLED` | Detect accounts without active CloudTrail |
| SSM managed instances | `EC2_INSTANCE_MANAGED_BY_SSM` | Detect EC2 not managed by Systems Manager |

### Rule Interface

```hcl
managed_rules = {
  s3_public_read = {
    name              = "s3-bucket-public-read-prohibited"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    description       = "Checks that S3 buckets do not allow public read access"
  }
  encrypted_volumes = {
    name              = "encrypted-volumes"
    source_identifier = "ENCRYPTED_VOLUMES"
    description       = "Checks whether EBS volumes are encrypted"
  }
}
```

## Detective vs Preventive Governance

| Control Type | Mechanism | Behavior |
|-------------|-----------|----------|
| Preventive | SCP (Service Control Policy) | **Blocks** actions before they occur |
| Detective | AWS Config rule | **Detects** non-compliance after the fact |

This module is strictly detective. It:
- Observes resource state
- Evaluates against rules
- Reports compliance status
- Does NOT block, delete, modify, or remediate anything

See ADR-003 for the full rationale.

## Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `recorder_name` | `string` | No | `"default"` | Recorder name |
| `recorder_role_arn` | `string` | Yes | — | IAM role ARN for Config |
| `recording_all_resources` | `bool` | No | `true` | Record all resource types |
| `selected_resource_types` | `list(string)` | No | `[]` | Specific types if not recording all |
| `include_global_resource_types` | `bool` | No | `true` | Include IAM/global resources |
| `delivery_channel_name` | `string` | No | `"default"` | Channel name |
| `delivery_s3_bucket` | `string` | Yes | — | S3 bucket for delivery |
| `delivery_s3_key_prefix` | `string` | No | `""` | Optional S3 prefix |
| `delivery_sns_topic_arn` | `string` | No | `""` | Optional SNS topic |
| `snapshot_delivery_frequency` | `string` | No | `"TwentyFour_Hours"` | Snapshot frequency |
| `managed_rules` | `map(object)` | No | `{}` | Managed Config rules |
| `tags` | `map(string)` | No | `{}` | Common tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `recorder_name` | `string` | Config recorder name |
| `delivery_channel_name` | `string` | Delivery channel name |
| `config_rule_ids` | `map(string)` | Rule key → rule ID |
| `config_rule_arns` | `map(string)` | Rule key → rule ARN |
| `config_rule_names` | `map(string)` | Rule key → rule name |
| `config_metadata` | `object` | Summary (bucket, frequency, counts, etc.) |

## Tag Behavior

Tags are merged with the following precedence (last wins):

1. Module-level `var.tags`
2. Per-rule `tags` field
3. Module-generated tags: `ManagedBy`, `Component`, `RuleKey`

Module-generated tags always take precedence to ensure traceability.

## Limitations

- One recorder per account per region (AWS limit)
- One delivery channel per account per region (AWS limit)
- Does not create the S3 bucket or IAM role (caller provides)
- Does not create organization-level Config aggregator
- Does not implement conformance packs
- Does not implement custom rules (Lambda-based)
- No automatic remediation (by design)
- Cannot validate that source identifiers exist at plan time

## Organizations Trusted Access

This module does **not** require AWS Organizations trusted access for
`config.amazonaws.com`. Normal account-level Config recording operates
independently. Organizations trusted access is only needed for:

- Organization-level Config aggregators
- Organization-level conformance packs

These capabilities will be added in a future module if needed.

## Example Usage

```hcl
module "config" {
  source = "../../modules/config"

  recorder_role_arn  = "arn:aws:iam::111122223333:role/aws-config-role"
  delivery_s3_bucket = "lz-config-delivery-111122223333"

  delivery_s3_key_prefix      = "config"
  snapshot_delivery_frequency = "Six_Hours"

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }

  managed_rules = {
    s3_public_read = {
      name              = "s3-bucket-public-read-prohibited"
      source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
      description       = "Checks that S3 buckets do not allow public read access"
    }
    encrypted_volumes = {
      name              = "encrypted-volumes"
      source_identifier = "ENCRYPTED_VOLUMES"
      description       = "Checks whether attached EBS volumes are encrypted"
    }
    root_mfa = {
      name                        = "root-account-mfa-enabled"
      source_identifier           = "ROOT_ACCOUNT_MFA_ENABLED"
      description                 = "Checks whether root account has MFA enabled"
      maximum_execution_frequency = "TwentyFour_Hours"
    }
    iam_password_policy = {
      name              = "iam-password-policy"
      source_identifier = "IAM_PASSWORD_POLICY"
      description       = "Checks IAM password policy meets requirements"
      input_parameters = {
        RequireUppercaseCharacters = "true"
        RequireLowercaseCharacters = "true"
        RequireNumbers             = "true"
        RequireSymbols             = "true"
        MinimumPasswordLength      = "14"
      }
    }
    cloudtrail_enabled = {
      name                        = "cloudtrail-enabled"
      source_identifier           = "CLOUD_TRAIL_ENABLED"
      description                 = "Checks whether CloudTrail is enabled"
      maximum_execution_frequency = "TwentyFour_Hours"
    }
    ec2_managed_by_ssm = {
      name              = "ec2-instance-managed-by-ssm"
      source_identifier = "EC2_INSTANCE_MANAGED_BY_SSM"
      description       = "Checks whether EC2 instances are managed by SSM"
    }
  }
}
```
