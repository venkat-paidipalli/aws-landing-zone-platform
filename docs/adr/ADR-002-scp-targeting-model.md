# ADR-002: SCP Targeting Model

## Status

Accepted

## Date

2026-08-18

## Context

Service Control Policies need to be attached to organizational targets (OUs
or the organization root). The SCP module must reference these targets, but
how it resolves them affects portability, testability, and coupling.

Options considered:

1. Hard-code AWS OU IDs directly in the SCP module
2. Import the organization module and read OU IDs from its resources
3. Accept a target-ID map as input, using logical path names as keys

The SCP module must work independently of the organization module to support
testing, separate deployment lifecycles, and environments where OU IDs differ.

## Decision

Use a **logical path → target ID map** pattern:

```
Policy configuration (logical paths)
        ↓
target_ids map (path → AWS ID)
        ↓
aws_organizations_policy_attachment (AWS ID)
```

The SCP module:
- Accepts `target_ids = map(string)` as input
- Policy targets reference canonical OU paths (e.g., `"Workloads/Prod"`)
- Validates that every target in a policy exists in the `target_ids` map
- Does not import or depend on the organization module

The caller wires the map:

```hcl
target_ids = merge(
  { "ROOT" = module.organization.root_id },
  module.organization.organizational_unit_ids
)
```

## Consequences

### Positive

- **Loose coupling**: The SCP module does not know or care how OUs were
  created. It could work with manually-created OUs, imported OUs, or OUs
  from a different module.

- **Testability**: Tests can supply synthetic target IDs without creating
  real OUs. Mock tests work cleanly with `target_ids = { "Security" = "ou-fake" }`.

- **Portability**: The same SCP configuration can be applied to different
  organizations by changing only the `target_ids` map.

- **Environment independence**: Dev/staging/prod environments have different
  OU IDs. Policies are defined once with logical paths; the mapping resolves
  per environment.

- **Plan-time validation**: Terraform validates that every policy target
  exists in the map before attempting to create attachments, catching
  typos and configuration drift early.

### Negative

- **Indirection**: The caller must explicitly wire the `target_ids` map.
  This is one additional step compared to tight module coupling.

- **Stale mappings**: If an OU is removed from the organization module but
  the SCP still references it, the error surfaces at plan time (from the
  validation) rather than at configuration time.

- **No automatic discovery**: Adding a new OU does not automatically make it
  available as an SCP target. The caller must update the wiring.

## Alternatives Considered

### Hard-coded OU IDs

```hcl
targets = ["ou-ab12-11111111", "ou-ab12-22222222"]
```

- **Pros**: Simplest implementation, no mapping needed
- **Cons**: Not portable, not testable, breaks across environments, unreadable

Rejected because it violates infrastructure-as-code principles and makes the
module unusable in different environments.

### Direct module dependency

```hcl
module "scp" {
  organization_module = module.organization
}
```

- **Pros**: No manual wiring, always in sync
- **Cons**: Tight coupling, cannot deploy SCP independently, cannot test SCP
  without the full organization module, circular dependency risk

Rejected because it prevents independent module testing and creates deployment
coupling that complicates the Terraform DAG.

### Data source lookup

```hcl
data "aws_organizations_organizational_units" "all" { ... }
```

- **Pros**: Always reflects live state
- **Cons**: Requires AWS API access at plan time, cannot work offline, adds
  latency, breaks mocked testing

Rejected because it contradicts the local-validation requirement and adds
runtime dependencies.
