# ADR-004: Account-Level Security vs Organization-Level Security

## Status

Accepted

## Date

2026-08-18

## Context

AWS security services like GuardDuty, Security Hub, and Config support two
deployment models:

1. **Account-level**: Each account independently enables and configures its
   own detector/recorder. No central administration.

2. **Organization-level**: A delegated administrator account manages the
   service across all member accounts. Central visibility, centralized
   findings, automated member enrollment.

Both models are valid, but they have different complexity, blast radius, and
testing characteristics. We need to decide which to implement first and how
to structure the modules.

## Decision

Build **account-level security controls first**, then add organization-wide
administration as a separate integration layer.

### Module Structure

| Module | Scope | When |
|--------|-------|------|
| `modules/guardduty` | Single-account detector | Now (Phase 1) |
| `modules/config` | Single-account recorder + rules | Now (Phase 1) |
| `modules/guardduty-org` | Delegated admin + member management | Future |
| `modules/config-org` | Aggregator + org conformance packs | Future |

### Composition Pattern

```
Environment layer (e.g., environments/security/)
├── calls modules/guardduty-org (delegated admin setup)
└── wires organization module outputs for member enrollment

Environment layer (e.g., environments/development/)
├── calls modules/guardduty (account-level detector)
└── receives settings from org admin
```

## Consequences

### Positive

- **Reduced blast radius**: An account-level module mistake affects only one
  account. An organization-level mistake could disable detection across every
  member account simultaneously.

- **Testability**: Account-level modules can be tested in complete isolation
  with mocked providers. No organization context, no member accounts, no
  delegated admin setup required.

- **Account independence**: Each account can function even if the organization
  admin is misconfigured. Standalone detectors continue operating independently.

- **Incremental deployment**: Can enable security services one account at a
  time. No big-bang organization-wide rollout required.

- **Clear separation of concerns**: The account-level module handles "what to
  detect" while the organization module handles "who manages whom."

### Negative

- **No central visibility initially**: Without organization-level aggregation,
  findings are siloed per-account until the org layer is built.

- **Manual consistency**: Without org-level administration, each account must
  be configured individually. Configuration drift is possible.

- **Duplicate configuration**: Same feature settings may be repeated across
  many account deployments until an org-level policy takes over.

## Alternatives Considered

### Organization-level first

- **Pros**: Central visibility from day one, automatic member enrollment,
  less per-account configuration
- **Cons**: Requires delegated admin setup, more complex testing, higher
  blast radius, depends on organization module working perfectly

Rejected for initial implementation because it creates a dependency chain
(org → delegated admin → member enrollment) that is harder to test and
riskier to deploy incrementally.

### Combined account + organization module

- **Pros**: Single module handles everything
- **Cons**: Complex conditional logic, hard to test individual pieces,
  mixing concerns (detection config vs admin relationships)

Rejected because it violates single-responsibility principle and makes
isolated testing impractical.

## Future Integration

When organization-level security is implemented:

1. **Security account** becomes the delegated administrator for GuardDuty,
   Security Hub, and Config.

2. **Organization module** enables trusted access:
   ```hcl
   aws_service_access_principals = [
     "guardduty.amazonaws.com",
     "config.amazonaws.com",
     "securityhub.amazonaws.com",
   ]
   ```

3. **Organization security modules** handle member enrollment, finding
   aggregation, and centralized configuration.

4. **Account-level modules** may become optional for member accounts
   (org admin auto-enables), but remain useful for:
   - The management account (often excluded from org admin)
   - Accounts not yet enrolled
   - Testing and validation

## Related Decisions

- **ADR-003**: Preventive vs detective controls (independent modules)
- **ADR-002**: SCP targeting model (loose coupling via maps)
- **ADR-001**: Monorepo structure (supports multiple related modules)
