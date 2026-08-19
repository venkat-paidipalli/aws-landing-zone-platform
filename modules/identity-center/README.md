# Identity Center Module

## Status

**Implemented** — manages IAM Identity Center permission sets and account
assignments.

## Purpose

Provides a reusable baseline for IAM Identity Center access management:

- Creates permission sets with configurable policies
- Attaches AWS managed and customer-managed policies
- Supports inline policies for custom restrictions
- Assigns permission sets to principals in specific accounts
- Enforces least-privilege through session duration and policy scope

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_ssoadmin_permission_set.this` | Permission sets |
| `aws_ssoadmin_managed_policy_attachment.this` | AWS managed policy attachments |
| `aws_ssoadmin_customer_managed_policy_attachment.this` | Customer policy attachments |
| `aws_ssoadmin_permission_set_inline_policy.this` | Inline policies (conditional) |
| `aws_ssoadmin_account_assignment.this` | Account assignments |

## What This Module Does NOT Manage

- Users or groups (caller provides principal IDs)
- External identity provider configuration (SAML, OIDC)
- SCIM provisioning
- Identity Center instance creation
- Delegated administration
- MFA policy
- Control Tower integration

## Architecture

```
External IdP (future)
        ↓ provisions
Identity Store (users/groups)
        ↓ principal IDs
This Module (permission sets + assignments)
        ↓ creates
Permission Sets → Account Assignments
```

## Instance Inputs

The module requires the Identity Center instance ARN. This is typically
discovered from the management account or provided by the environment layer.

```hcl
instance_arn = "arn:aws:sso:::instance/ssoins-..."
```

## Permission Set Model

```hcl
permission_sets = {
  readonly = {
    name             = "ReadOnly"
    description      = "Read-only access"
    session_duration = "PT1H"
    aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  }
}
```

## Session Duration

ISO-8601 format. Default: `PT1H` (1 hour).

| Duration | Use Case |
|----------|----------|
| `PT1H` | Default, security-sensitive roles |
| `PT4H` | Developer workloads |
| `PT8H` | Extended operations |

Shorter sessions reduce the window for credential misuse. Prefer short
defaults and extend only with justification.

## Least-Privilege Model

| Role | Policy | Rationale |
|------|--------|-----------|
| ReadOnly | `ReadOnlyAccess` | View-only, no modification |
| Developer | `PowerUserAccess` | Workload dev, no IAM/org changes |
| SecurityAudit | `SecurityAudit` | Security service read access |
| NetworkAdmin | Custom | Network operations scope |
| PlatformAdmin | `AdministratorAccess` + inline deny | Broad access with guardrails |

PlatformAdmin uses AdministratorAccess for portfolio demonstration but adds
an inline deny policy preventing dangerous org-level actions.

## Assignment Model

```hcl
assignments = {
  dev_team_dev_account = {
    permission_set_key = "developer"
    principal_id       = "group-id-from-identity-store"
    principal_type     = "GROUP"
    target_account_id  = "444455556666"
  }
}
```

Prefer GROUP assignments over USER for scalability.

## Inputs

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `instance_arn` | `string` | Yes | — | SSO instance ARN |
| `permission_sets` | `map(object)` | No | `{}` | Permission set definitions |
| `assignments` | `map(object)` | No | `{}` | Account assignments |
| `tags` | `map(string)` | No | `{}` | Common tags |

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `permission_set_arns` | `map(string)` | Key → ARN |
| `permission_set_names` | `map(string)` | Key → name |
| `assignment_ids` | `map(string)` | Key → assignment ID |
| `identity_center_metadata` | `object` | Summary counts |

## Limitations

- Does not create users/groups (caller provides IDs)
- Permission set names max 32 characters (AWS limit)
- Cannot validate managed policy existence at plan time
- Cannot validate principal ID existence at plan time
- Inline policy validated as JSON but not semantically
- No external IdP/SCIM integration
- Instance ARN must be known ahead of time

## Example Usage

```hcl
module "identity_center" {
  source = "../../modules/identity-center"

  instance_arn = "arn:aws:sso:::instance/ssoins-0000000000000001"

  permission_sets = {
    readonly = {
      name                 = "ReadOnly"
      description          = "Read-only access"
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
    developer = {
      name             = "Developer"
      session_duration = "PT4H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
    }
  }

  assignments = {
    devs_in_dev = {
      permission_set_key = "developer"
      principal_id       = "group-id-12345"
      principal_type     = "GROUP"
      target_account_id  = "444455556666"
    }
  }

  tags = { Project = "landing-zone" }
}
```
