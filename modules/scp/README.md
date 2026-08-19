# SCP Module

## Status

**Implemented** — creates Service Control Policies and attaches them to
specified organizational targets.

## Purpose

Manages SCP lifecycle for an AWS Organization:

- Creates SCP policy resources from caller-provided policy documents
- Attaches policies to specified OU targets
- Generates dynamic region-restriction policy content
- Validates target references at plan time

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_organizations_policy.this` | Service Control Policies |
| `aws_organizations_policy_attachment.this` | Policy-to-target attachments |

## What This Module Does NOT Manage

- The organization itself (use the `organization` module)
- OU creation (use the `organization` module)
- The default FullAWSAccess SCP (managed by AWS)
- SCP content authoring (caller provides JSON documents)
- Tag policies, backup policies, or AI opt-out policies

## Input Contract

### Policies

```hcl
variable "policies" {
  type = map(object({
    name        = string           # Display name (1-128 chars)
    description = string           # Purpose description (max 512 chars)
    content     = string           # Policy document JSON
    targets     = list(string)     # Canonical OU paths to attach to
    tags        = optional(map(string), {})
  }))
}
```

### Target IDs

```hcl
variable "target_ids" {
  type = map(string)
  # Maps canonical OU path → AWS OU/Root ID
}
```

### Approved Regions (for region-deny generation)

```hcl
variable "approved_regions" {
  type    = list(string)
  default = []
  # e.g., ["us-east-1", "us-west-2"]
}
```

## Target Resolution

Policies reference targets using **canonical OU paths** (e.g., `"Security"`,
`"Workloads/NonProd"`). The caller provides a `target_ids` map that resolves
these paths to actual AWS OU IDs.

This design:
- Decouples the SCP module from the organization module
- Makes policies portable across environments
- Enables testing without real AWS IDs
- Allows targeting the organization root via `"ROOT"` key

Typical wiring from the organization module:

```hcl
module "scp" {
  source = "../../modules/scp"

  target_ids = merge(
    { "ROOT" = module.organization.root_id },
    module.organization.organizational_unit_ids
  )

  # ... policies ...
}
```

## Policy Library

### Deny Root User (`deny-root-user.json`)

**What it prevents:** All API actions performed by the AWS account root user
in member accounts.

**Why it exists:** Root user credentials are the highest-privilege access path.
They should never be used for routine operations. This SCP provides a
preventive guardrail.

**What it does NOT prevent:**
- Root user access in the management account (SCPs do not apply there)
- Console sign-in (SCPs cannot block authentication, only API actions)
- Password recovery flows

**Operational considerations:**
- Some account-level operations require root (e.g., enabling certain support
  tiers, closing the account). If needed, temporarily detach this SCP.
- AWS recommends enabling MFA on root in addition to this SCP.

### Region Restriction (dynamic, via `approved_regions`)

**What it prevents:** API actions in non-approved AWS regions for regional
services.

**Why it exists:** Limits blast radius, ensures compliance with data residency
requirements, and prevents shadow infrastructure in unexpected regions.

**Global service exceptions:** The following services operate globally and are
excluded from region restrictions (denying them would break AWS functionality):

- IAM, STS, Organizations, Route 53, CloudFront, WAF/WAFv2
- Health, Support, Trusted Advisor, Budgets, Cost Explorer
- Shield, Global Accelerator, Access Analyzer, Account management
- Import/Export, Well-Architected, Chatbot, Alexa for Business

**Configuration:** Pass `approved_regions = ["us-east-1", "us-west-2"]` to
generate the policy. The output `region_deny_policy_content` provides the
JSON string to use as the policy `content`.

### Require IMDSv2 (`require-imdsv2.json`)

**What it prevents:**
- Launching EC2 instances without requiring IMDSv2 (`HttpTokens = required`)
- Modifying instance metadata options to disable IMDSv2

**Why it exists:** IMDSv1 is vulnerable to SSRF attacks that can steal
instance credentials. IMDSv2 requires session tokens, mitigating this vector.

**Limitations:**
- Only covers `ec2:RunInstances` and `ec2:ModifyInstanceMetadataOptions`
- Does not retroactively fix existing instances launched before the SCP
- Launch templates and Auto Scaling groups that specify metadata options
  are covered; those that inherit defaults are NOT covered by this SCP
- For complete enforcement, combine with AWS Config rules that detect
  non-compliant running instances

## Attachment Safety

**Conservative design principles:**

1. No implicit root attachment — every target must be explicitly listed
2. Each policy requires at least one target (no orphan policies)
3. All targets are validated against `target_ids` at plan time
4. Attachment keys are deterministic (`policy_key:target_path`)

**Recovery considerations:**

- If an SCP locks out access, use the management account (exempt from SCPs)
  to detach or modify the policy
- Always test SCPs on non-production OUs before applying to production
- The Suspended OU should have a deny-all SCP; other OUs should be cautious
- Keep the default `FullAWSAccess` SCP attached at the root (AWS creates it)

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `policy_ids` | `map(string)` | Policy key → AWS policy ID |
| `policy_arns` | `map(string)` | Policy key → AWS policy ARN |
| `policy_attachment_targets` | `map(string)` | Attachment key → target ID |
| `policy_metadata` | `object` | Summary (counts, target paths) |
| `region_deny_policy_content` | `string` | Generated region-deny JSON |

## Limitations

- Policy document size limit: 5,120 bytes (AWS Organizations limit)
- Maximum 5 SCPs per target (AWS limit)
- SCPs do not apply to the management account
- Cannot validate policy document syntax at plan time (only at apply)
- Region-deny global service list may need updates as AWS adds services
- Cannot detect SCP conflicts with other policies at plan time

## Example Usage

```hcl
module "scp" {
  source = "../../modules/scp"

  approved_regions = ["us-east-1", "us-west-2"]

  target_ids = {
    "ROOT"              = "r-ab12"
    "Security"          = "ou-ab12-11111111"
    "Infrastructure"    = "ou-ab12-22222222"
    "Workloads/NonProd" = "ou-ab12-33333333"
    "Workloads/Prod"    = "ou-ab12-44444444"
    "Sandbox"           = "ou-ab12-55555555"
    "Suspended"         = "ou-ab12-66666666"
  }

  policies = {
    deny_root_user = {
      name        = "deny-root-user"
      description = "Deny all actions by root user in member accounts"
      content     = file("${path.module}/../../policies/scp/deny-root-user.json")
      targets     = ["Security", "Infrastructure", "Workloads/NonProd", "Workloads/Prod", "Sandbox"]
    }
    deny_unapproved_regions = {
      name        = "deny-unapproved-regions"
      description = "Restrict operations to approved AWS regions"
      content     = module.scp.region_deny_policy_content
      targets     = ["Workloads/NonProd", "Workloads/Prod", "Sandbox"]
    }
    require_imdsv2 = {
      name        = "require-imdsv2"
      description = "Require IMDSv2 for all EC2 instance launches"
      content     = file("${path.module}/../../policies/scp/require-imdsv2.json")
      targets     = ["Workloads/NonProd", "Workloads/Prod"]
    }
  }
}
```
