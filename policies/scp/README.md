# SCP Policy Library

Static and template SCP policy documents for the landing zone.

## Policies

| File | Type | Description |
|------|------|-------------|
| `deny-root-user.json` | Static | Denies all actions by the root user |
| `require-imdsv2.json` | Static | Requires IMDSv2 for EC2 instances |
| `deny-unapproved-regions.example.json` | Example | Region restriction (generated dynamically) |

## Static vs Dynamic Policies

- **Static policies** (`*.json`): Fixed policy documents loaded via `file()`.
  Use these when the policy content never changes per deployment.

- **Dynamic policies**: Generated via `jsonencode()` in Terraform. Use these
  when the policy content needs to be parameterized (e.g., approved regions).
  The region-deny policy is dynamic because the allowed regions list varies
  per organization.

## Usage

Static policies are loaded in Terraform via:

```hcl
content = file("${path.module}/../../policies/scp/deny-root-user.json")
```

Or by passing the JSON string directly to the SCP module's `content` field.
