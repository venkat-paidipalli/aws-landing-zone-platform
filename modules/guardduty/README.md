# GuardDuty Module

## Status

**Implemented** — creates an account-level GuardDuty detector with
configurable protection features.

## Purpose

Enables Amazon GuardDuty threat detection for a single AWS account:

- Activates the GuardDuty detector
- Configures finding publishing frequency
- Enables/disables optional protection features
- Provides detection-only security (no automated remediation)

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_guardduty_detector.this` | GuardDuty detector with protection features |

## Detector Behavior

GuardDuty continuously monitors for threats by analyzing:

- AWS CloudTrail management events
- VPC Flow Logs
- DNS query logs

These foundational data sources are always monitored when the detector is
enabled. No additional configuration is required for them.

## Publishing Frequency

| Value | Behavior | Use Case |
|-------|----------|----------|
| `FIFTEEN_MINUTES` (default) | Findings published every 15 minutes | Production, rapid response needed |
| `ONE_HOUR` | Findings published hourly | Staging environments |
| `SIX_HOURS` | Findings published every 6 hours | Cost-sensitive, sandbox |

Default is `FIFTEEN_MINUTES` for rapid threat visibility. Findings are
published to CloudWatch Events regardless of this setting (this controls
the refresh frequency for updated/recurring findings).

## Protection Features

| Feature | Variable | Default | Description |
|---------|----------|---------|-------------|
| S3 Protection | `enable_s3_protection` | `true` | Monitors S3 data plane events for threats |
| Kubernetes Protection | `enable_kubernetes_protection` | `false` | Monitors EKS audit logs |
| Malware Protection | `enable_malware_protection` | `false` | Scans EBS volumes on compromised instances |

### Default Feature Decisions

| Feature | Default | Rationale |
|---------|---------|-----------|
| S3 Protection | Enabled | Low cost, high value, no prerequisites |
| Kubernetes | Disabled | Requires EKS clusters, additional cost, not universally needed |
| Malware | Disabled | Significant cost per scan, triggered by findings, advanced use case |

### Cost Considerations

- **Base detector**: Charged per volume of CloudTrail events and VPC Flow Logs analyzed
- **S3 protection**: Additional charge per million S3 data events analyzed
- **Kubernetes**: Additional charge per million EKS audit log events
- **Malware protection**: Charged per GB scanned (triggered only on findings)

Enable features based on actual workload needs. Not every account requires
every protection feature.

### Regional Considerations

- GuardDuty must be enabled per-region (this module handles one region)
- Multi-region deployment requires calling this module once per region
- S3 protection operates on data events in the deployed region
- Kubernetes protection requires EKS clusters in the same region

## No Automated Remediation

This module is **detection only**. It:

- Detects threats and generates findings
- Publishes findings to CloudWatch Events
- Does NOT block, quarantine, isolate, or terminate resources
- Does NOT create EventBridge rules
- Does NOT trigger Lambda functions
- Does NOT modify security groups or NACLs

Finding response belongs to a separate remediation/incident-response layer.

## No Organization Administration

This module creates a standalone per-account detector. It does NOT:

- Configure delegated administrator
- Invite or manage member accounts
- Create organization-wide detector policies
- Require AWS Organizations trusted access

Organization-wide GuardDuty administration is a separate concern that will
be implemented in a future integration layer. See ADR-004.

## Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `enable` | `bool` | No | `true` | Enable/disable the detector |
| `finding_publishing_frequency` | `string` | No | `"FIFTEEN_MINUTES"` | Finding refresh frequency |
| `enable_s3_protection` | `bool` | No | `true` | S3 data event monitoring |
| `enable_kubernetes_protection` | `bool` | No | `false` | EKS audit log monitoring |
| `enable_malware_protection` | `bool` | No | `false` | EBS malware scanning |
| `tags` | `map(string)` | No | `{}` | Tags (no aws: prefix) |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `detector_id` | `string` | GuardDuty detector ID |
| `detector_arn` | `string` | GuardDuty detector ARN |
| `detector_enabled` | `bool` | Whether detector is enabled |
| `enabled_features` | `map(bool)` | Feature enablement status |
| `guardduty_metadata` | `object` | Summary configuration |

## Tag Behavior

Tags merged with precedence (last wins):

1. Caller-provided `var.tags`
2. Module-generated tags: `ManagedBy = "terraform"`, `Component = "guardduty"`

Module-generated tags always take precedence.

## Limitations

- One detector per account per region (AWS limit)
- Cannot retroactively analyze historical events before enablement
- Malware scans triggered only by existing findings (not continuous)
- Kubernetes protection requires active EKS clusters
- No organization-wide administration (separate module needed)
- Finding export to S3 not configured (separate concern)
- No custom threat lists or trusted IP lists

## Example Usage

```hcl
# Production account - full protection
module "guardduty" {
  source = "../../modules/guardduty"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  enable_s3_protection         = true
  enable_kubernetes_protection = true
  enable_malware_protection    = true

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }
}

# Sandbox account - minimal detection, lower cost
module "guardduty_sandbox" {
  source = "../../modules/guardduty"

  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"

  enable_s3_protection         = true
  enable_kubernetes_protection = false
  enable_malware_protection    = false

  tags = {
    Environment = "sandbox"
    Project     = "landing-zone"
  }
}
```
