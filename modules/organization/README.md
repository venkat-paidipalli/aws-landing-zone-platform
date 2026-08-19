# Organization Module

## Status

**Implemented** — this module creates AWS Organizations resources including
the organization, organizational units, and member accounts.

## Purpose

Manages the structure of an AWS Organization including:

- Organization creation and feature set configuration
- Organizational Unit (OU) hierarchy (up to 2 levels)
- Member account provisioning and OU placement
- Tagging governance across all managed resources

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_organizations_organization.this` | The AWS Organization |
| `aws_organizations_organizational_unit.top_level` | Top-level OUs (parent = Root) |
| `aws_organizations_organizational_unit.nested` | Nested OUs (parent = another OU) |
| `aws_organizations_account.this` | Member accounts |

## What This Module Does NOT Manage

- The management account (it already exists before the org is created)
- Service Control Policies (handled by a dedicated `scp` module)
- IAM roles within member accounts
- Account-level baseline configuration
- AWS Control Tower enrollment
- Delegated administrator assignments

## OU Hierarchy Behavior

OUs are created in two passes:

1. **Top-level OUs** — directly under the organization root (`parent = "ROOT"`)
2. **Nested OUs** — under a top-level OU (e.g., `"Workloads/NonProd"` under `"Workloads"`)

This supports the standard landing zone pattern:

```
Root
├── Security           (top-level)
├── Infrastructure     (top-level)
├── Workloads          (top-level)
│   ├── NonProd        (nested)
│   └── Prod           (nested)
├── Sandbox            (top-level)
└── Suspended          (top-level)
```

### Limitation (v1)

The current implementation supports exactly **2 levels** of OU nesting
(top-level + one child). AWS allows up to 5 levels. Deeper nesting would
require additional resource blocks or a recursive module pattern. This is
sufficient for the current landing zone design.

## Account Creation Behavior

Member accounts are created with:

- `close_on_deletion = false` — destroying the Terraform resource removes the
  account from the organization but does **not** permanently close it
- `lifecycle.prevent_destroy = true` — Terraform refuses to plan destruction
  of account resources (must be explicitly removed to destroy)
- `ignore_changes = [email]` — AWS does not support changing account email
  via the Organizations API after creation

### Account Deletion Safety

| Scenario | Behavior |
|----------|----------|
| `terraform destroy` | **Blocked** by `prevent_destroy = true` |
| Remove `prevent_destroy`, then destroy | Account removed from org, becomes standalone |
| `close_on_deletion = true` (not set) | Would permanently close the account (we don't do this) |

**Intentional friction:** To actually remove an account, you must:
1. Remove `prevent_destroy` from the lifecycle block
2. Run `terraform apply` to update the resource
3. Run `terraform destroy -target` on the specific account
4. The account becomes standalone (not closed)

## Tag Behavior

Tags are applied with the following precedence (last wins):

1. User-provided tags from the `tags` field in the variable
2. Module-generated tags added automatically:

| Tag | Applied To | Value |
|-----|-----------|-------|
| `ManagedBy` | OUs, Accounts | `"terraform"` |
| `OUPath` | OUs | The canonical OU path |
| `AccountKey` | Accounts | The logical map key |
| `Environment` | Accounts | From user tags or `"unspecified"` |

User tags take precedence for all keys except the module-generated ones listed
above. The module-generated tags are merged on top of user tags.

## Inputs

### Organization Metadata

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `organization_name` | `string` | Yes | — | Logical name (2-64 chars, lowercase slug) |
| `feature_set` | `string` | No | `"ALL"` | `ALL` or `CONSOLIDATED_BILLING` |

### Organizational Units

```hcl
variable "organizational_units" {
  type = map(object({
    name        = optional(string)
    parent      = string
    description = optional(string, "")
    tags        = optional(map(string), {})
  }))
}
```

### Accounts

```hcl
variable "accounts" {
  type = map(object({
    name      = string
    email     = string
    ou_path   = string
    role_name = optional(string, "OrganizationAccountAccessRole")
    tags      = optional(map(string), {})
  }))
}
```

## OU Path Convention

- `ROOT` is the implicit parent (never part of path strings)
- `/` separates hierarchy levels: `"Workloads/NonProd"`
- No leading, trailing, or consecutive slashes
- Parent must be `"ROOT"` or another path defined in the same map
- Display name defaults to last segment of the path

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `organization_id` | `string` | AWS Organization ID |
| `organization_arn` | `string` | AWS Organization ARN |
| `root_id` | `string` | Organization root ID |
| `organizational_unit_ids` | `map(string)` | OU path → OU ID |
| `organizational_unit_arns` | `map(string)` | OU path → OU ARN |
| `account_ids` | `map(string)` | Account key → AWS account ID |
| `account_arns` | `map(string)` | Account key → account ARN |
| `account_parent_map` | `map(string)` | Account key → parent OU ID |
| `organization_metadata` | `object` | Summary (name, feature_set, counts) |

## AWS Service Access Principals

The organization currently has no service access principals enabled.
Principals will be added incrementally as each service module is implemented:

| Principal | Module | Status |
|-----------|--------|--------|
| `cloudtrail.amazonaws.com` | CloudTrail | Not yet implemented |
| `config.amazonaws.com` | Config | Not yet implemented |
| `guardduty.amazonaws.com` | GuardDuty | Not yet implemented |
| `securityhub.amazonaws.com` | Security Hub | Not yet implemented |

## Enabled Policy Types

| Policy Type | Purpose | Status |
|-------------|---------|--------|
| `SERVICE_CONTROL_POLICY` | Preventive guardrails (SCPs) | Enabled |

## Limitations

- Maximum 2 levels of OU nesting (top-level + one child)
- Cannot detect circular OU parent references at plan time
- Account email cannot be changed after creation
- Account closure requires manual steps beyond Terraform
- Management account is not managed by this module

## Example Usage

```hcl
provider "aws" {
  region = "us-east-1"
  # Assumes execution in the management account
}

module "organization" {
  source = "../../modules/organization"

  organization_name = "portfolio-platform"
  feature_set       = "ALL"

  organizational_units = {
    Security = {
      parent      = "ROOT"
      description = "Security foundation accounts"
      tags        = { CostCenter = "cc-security" }
    }
    Infrastructure = {
      parent      = "ROOT"
      description = "Shared infrastructure accounts"
    }
    Workloads = {
      parent      = "ROOT"
      description = "Application workload accounts"
    }
    "Workloads/NonProd" = {
      parent      = "Workloads"
      description = "Non-production workload accounts"
    }
    "Workloads/Prod" = {
      parent      = "Workloads"
      description = "Production workload accounts"
    }
    Sandbox = {
      parent      = "ROOT"
      description = "Experimentation and learning"
    }
    Suspended = {
      parent      = "ROOT"
      description = "Quarantined or decommissioned accounts"
    }
  }

  accounts = {
    security = {
      name    = "lz-security"
      email   = "aws+security@example.invalid"
      ou_path = "Security"
      tags    = { Environment = "production", Project = "landing-zone" }
    }
    log_archive = {
      name    = "lz-log-archive"
      email   = "aws+log-archive@example.invalid"
      ou_path = "Security"
      tags    = { Environment = "production", Project = "landing-zone" }
    }
    network = {
      name    = "lz-network"
      email   = "aws+network@example.invalid"
      ou_path = "Infrastructure"
      tags    = { Environment = "production", Project = "landing-zone" }
    }
  }
}
```
