# Security Hub Module

## Status

**Implemented** — enables account-level AWS Security Hub with configurable
standards subscriptions and control overrides.

## Purpose

Deploys an account-level Security Hub baseline that:

- Enables Security Hub for compliance aggregation
- Subscribes to configurable security standards
- Allows disabling specific controls with documented justification
- Provides compliance posture visibility (no remediation)

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_securityhub_account.this` | Enables Security Hub in the account |
| `aws_securityhub_standards_subscription.this` | Standards subscriptions |
| `aws_securityhub_standards_control_association.disabled` | Control disable overrides |

## Architecture

```
AWS Config (resource state)
        ↓ evidence
Security Hub (compliance evaluation)
        ↑ findings
GuardDuty (threat detection)
```

Security Hub aggregates findings from multiple sources:
- **AWS Config**: Provides resource configuration evidence for security controls
- **GuardDuty**: Feeds threat-detection findings into Security Hub automatically
- **Other services**: Inspector, Macie, Firewall Manager (when enabled)

## Standards

### Supported Standards

| Standard | ARN Pattern | Description |
|----------|-------------|-------------|
| AWS Foundational Security Best Practices | `arn:aws:securityhub:<region>::standards/aws-foundational-security-best-practices/v/1.0.0` | AWS-curated best practices |
| CIS AWS Foundations 1.4 | `arn:aws:securityhub:<region>::standards/cis-aws-foundations-benchmark/v/1.4.0` | CIS benchmark controls |
| CIS AWS Foundations 1.2 | `arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0` | Legacy CIS benchmark |

### Default Standards Decision

By default, `enable_default_standards = false`. This means:

- No standards are automatically enabled when Security Hub activates
- Standards are managed **explicitly** via the `standards` variable
- This prevents unexpected compliance noise from unreviewed standards
- The caller decides exactly which standards to subscribe to

**Rationale:** Automatic default standards can create hundreds of findings on
first enablement, overwhelming teams before they understand their baseline.
Explicit management ensures deliberate adoption.

### Recommended Production Configuration

```hcl
standards = {
  aws_foundational = {
    arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
  }
}
```

Start with AWS Foundational Security Best Practices — it provides comprehensive
coverage without the CIS-specific operational overhead. Add CIS later when the
team is ready to address its stricter requirements.

## Control Overrides

Individual controls can be disabled with documented justification:

```hcl
disabled_controls = {
  disable_s3_logging = {
    standards_arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
    control_id    = "S3.9"
    reason        = "S3 access logging handled by centralized CloudTrail"
  }
}
```

**Guidelines:**
- Only disable controls with clear business justification
- Document the `reason` for audit/compliance purposes
- Review disabled controls periodically
- Prefer addressing findings over disabling controls

## Config Relationship

Security Hub **requires** AWS Config to be enabled for security controls to
produce findings. Without Config:
- Security Hub activates successfully
- Standards subscribe successfully
- Controls show "No data available" instead of compliance status

This module does NOT enforce the Config dependency — the caller must ensure
Config is enabled in the same account/region. This keeps modules independent.

## GuardDuty Relationship

When both GuardDuty and Security Hub are enabled in the same account/region:
- GuardDuty findings automatically appear in Security Hub
- No explicit integration resource is needed
- The integration is handled by AWS natively

This module does NOT create explicit product subscriptions for GuardDuty —
the native integration is automatic.

## Regional Behavior

- Security Hub is regional — must be enabled per-region
- Standards subscriptions are per-region
- Cross-region aggregation requires a separate aggregation resource (not in scope)
- Standard ARNs contain the region (except some legacy CIS ARNs)

## Cost Considerations

- Security Hub charges per finding ingested per month (first 10,000 free)
- More standards = more findings = higher cost
- Disabled controls reduce finding volume (and cost)
- GuardDuty findings ingested by Security Hub incur additional cost
- Start with one standard to understand cost baseline

## No Automated Remediation

This module is **compliance visibility only**. It:
- Aggregates and evaluates security findings
- Reports compliance status per-control
- Does NOT block, modify, delete, or remediate resources
- Does NOT create EventBridge rules for findings
- Does NOT trigger Lambda or SSM automation

Remediation belongs to a future optional layer.

## No Organization Administration

This module creates standalone per-account Security Hub. It does NOT:
- Configure delegated administrator
- Enroll member accounts
- Enable central configuration
- Set up cross-account finding aggregation
- Require AWS Organizations trusted access

Organization-wide Security Hub administration is a separate concern.
See ADR-004 and ADR-005.

## Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `enable_default_standards` | `bool` | No | `false` | Auto-enable AWS defaults |
| `auto_enable_controls` | `bool` | No | `true` | Auto-enable new controls |
| `standards` | `map(object)` | No | `{}` | Standards to subscribe to |
| `disabled_controls` | `map(object)` | No | `{}` | Controls to disable |
| `tags` | `map(string)` | No | `{}` | Tags (no aws: prefix) |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `security_hub_enabled` | `bool` | Always true (resource exists) |
| `enabled_standards` | `map(string)` | Standard key → ARN |
| `standard_subscription_arns` | `list(string)` | All subscription ARNs |
| `disabled_controls` | `map(object)` | Disabled control details |
| `security_hub_metadata` | `object` | Summary configuration |

## Limitations

- One Security Hub instance per account per region
- Cannot validate standard ARNs at plan time (only at apply)
- Cannot validate control IDs exist at plan time
- Requires Config for controls to produce findings (not enforced)
- No cross-region aggregation (separate resource)
- No organization administration (separate module)
- Tags limited to what the provider supports for SecurityHub resources

## Example Usage

```hcl
module "security_hub" {
  source = "../../modules/security-hub"

  enable_default_standards = false
  auto_enable_controls     = true

  standards = {
    aws_foundational = {
      arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
    }
    cis_1_4 = {
      arn     = "arn:aws:securityhub:us-east-1::standards/cis-aws-foundations-benchmark/v/1.4.0"
      enabled = false  # Subscribe later after foundational is clean
    }
  }

  disabled_controls = {
    disable_cloudtrail_multi_region = {
      standards_arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
      control_id    = "CloudTrail.5"
      reason        = "Multi-region trail managed by organization-level CloudTrail module"
    }
  }

  tags = {
    Environment = "production"
    Project     = "landing-zone"
  }
}
```
