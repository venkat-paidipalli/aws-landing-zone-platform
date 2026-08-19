# ADR-005: Security Findings Aggregation Boundary

## Status

Accepted

## Date

2026-08-18

## Context

AWS Security Hub serves two distinct roles:

1. **Account-level compliance**: Evaluates security controls against standards,
   reports per-account posture, integrates findings from GuardDuty/Config.

2. **Organization-level aggregation**: Centralized view across all accounts,
   delegated administrator, automatic member enrollment, cross-account
   finding visibility.

These roles have different blast radius, operational complexity, and
deployment dependencies. We need to decide how to structure them.

### Finding Sources in This Platform

```
Per-account sources:
  AWS Config → resource compliance findings
  GuardDuty → threat detection findings
  Security Hub controls → security standard findings

Organization-level aggregation:
  Security Hub (delegated admin) → cross-account findings view
  Config Aggregator → cross-account resource state
  GuardDuty (delegated admin) → cross-account threat findings
```

## Decision

Separate **account-level Security Hub enablement** from **organization-level
security administration and cross-account aggregation**.

### Current Implementation (Phase 1)

| Module | Scope | Responsibility |
|--------|-------|----------------|
| `modules/security-hub` | Single account | Enable Hub, subscribe standards, control overrides |
| `modules/guardduty` | Single account | Enable detector, configure features |
| `modules/config` | Single account | Enable recorder, delivery, rules |

### Future Implementation (Phase 2+)

| Module | Scope | Responsibility |
|--------|-------|----------------|
| `modules/securityhub-org` | Organization | Delegated admin, central config, member enrollment |
| `modules/guardduty-org` | Organization | Delegated admin, member management |
| `modules/config-org` | Organization | Aggregator, org conformance packs |

### Composition Pattern

```
Security account (delegated admin):
├── modules/securityhub-org  → manages all members
├── modules/guardduty-org    → manages all members
└── modules/config-org       → aggregates all accounts

Each member account:
├── modules/security-hub     → account-level (may be auto-enabled by org)
├── modules/guardduty        → account-level (may be auto-enabled by org)
└── modules/config           → account-level recorder + rules
```

## Consequences

### Positive

- **Independent blast radius**: Account-level module mistakes affect one
  account. Organization-level mistakes could disable security across the
  entire organization.

- **Phased adoption**: Teams can enable Security Hub per-account first,
  understand their findings baseline, then opt into organization-level
  aggregation when ready.

- **Testability**: Account-level modules test in isolation with mocked
  providers. No organization context, delegated admin, or member accounts
  needed for unit testing.

- **Clear ownership model**: The Security/Audit account owns organization
  administration. Individual accounts own their local configuration.

- **Graceful degradation**: If organization administration fails or is
  misconfigured, individual account detectors and hubs continue operating
  independently.

- **Future Control Tower compatibility**: When Control Tower is adopted,
  it manages organization-level security. Account-level modules remain
  useful for accounts not yet enrolled or for custom configurations
  beyond Control Tower's scope.

### Negative

- **No cross-account visibility initially**: Findings are siloed per-account
  until the organization layer is built.

- **Potential inconsistency**: Without central configuration, account-level
  settings may drift. Organization administration solves this with policy
  enforcement.

- **Duplicate effort**: The same standards/controls must be configured per
  account (or via shared tfvars) until the org layer automates it.

## Alternatives Considered

### Organization-level first

- **Pros**: Immediate cross-account visibility, automatic member enrollment,
  consistent configuration
- **Cons**: Requires delegated admin setup, depends on organization module,
  higher blast radius, harder to test, all-or-nothing rollout

Rejected for initial implementation because the dependency chain is complex
and the blast radius is organization-wide.

### Combined account + organization module

- **Pros**: Single module for everything
- **Cons**: Massive complexity, conditional logic for admin vs member,
  impossible to test independently, mixed concerns

Rejected — violates single-responsibility principle.

### Skip account-level, only organization

- **Pros**: Less code, fewer modules
- **Cons**: Cannot test without full org setup, management account gaps,
  no fallback if org admin fails

Rejected because the management account and any accounts not enrolled
still need standalone Security Hub.

## Future Integration Points

1. **Organization module** enables trusted access:
   ```
   securityhub.amazonaws.com
   guardduty.amazonaws.com
   config.amazonaws.com
   ```

2. **Security account** becomes delegated administrator for all three services.

3. **Organization security modules** handle:
   - Member auto-enrollment
   - Central configuration policies
   - Finding aggregation regions
   - Cross-account finding visibility

4. **Account-level modules** remain for:
   - Management account (often excluded from org admin)
   - Custom per-account overrides beyond org policy
   - Testing and validation
   - Accounts in transition

## Related Decisions

- **ADR-003**: Preventive vs detective controls (independent modules)
- **ADR-004**: Account-level vs organization-level security (phased approach)
- **This ADR**: Security findings aggregation boundary (account first, org later)
