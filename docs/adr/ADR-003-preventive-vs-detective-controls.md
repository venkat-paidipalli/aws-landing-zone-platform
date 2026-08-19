# ADR-003: Preventive vs Detective Controls

## Status

Accepted

## Date

2026-08-18

## Context

A well-architected landing zone requires multiple layers of governance. Two
primary patterns exist:

- **Preventive controls** — block actions before they happen
- **Detective controls** — observe actions after they happen and report
  non-compliance

AWS provides distinct services for each pattern:

| Pattern | AWS Service | Mechanism |
|---------|-------------|-----------|
| Preventive | Service Control Policies (SCPs) | IAM policy evaluation denies action |
| Detective | AWS Config | Evaluates resource state against rules |

Both are needed, but they have fundamentally different operational
characteristics, blast radii, and failure modes.

## Decision

Implement preventive and detective controls as **independent, separately
deployable modules**:

| Module | Type | Behavior |
|--------|------|----------|
| `modules/scp` | Preventive | Blocks prohibited actions organization-wide |
| `modules/config` | Detective | Evaluates compliance per-account, reports only |

Key principles:

1. **The SCP module never reads or remediates state.** It only defines what
   is denied.

2. **The Config module never blocks or modifies resources.** It only observes
   and reports compliance status.

3. **Neither module depends on the other.** They can be deployed, tested,
   and updated independently.

4. **No automatic remediation.** Config findings are informational. Humans
   decide what to fix and when.

## Consequences

### Positive

- **Independent blast radius**: An SCP mistake locks people out instantly;
  a Config mistake only produces incorrect compliance reports. Separating
  them limits the damage of errors in either layer.

- **Independent testing**: Each module has its own mocked test suite. SCP
  tests validate policy documents and attachments. Config tests validate
  recorder setup and rule definitions. Neither requires the other.

- **Phased rollout**: Organizations can deploy detective controls first
  (observe mode) to understand their compliance posture before adding
  preventive controls. This is safer during initial adoption.

- **Clear ownership boundaries**: Security teams own detective controls
  (what to monitor). Platform teams own preventive controls (what to
  block). The modules mirror these organizational boundaries.

- **Future remediation layer**: When auto-remediation is desired, it becomes
  a third layer that consumes Config findings. It doesn't need to be
  coupled to the rule definitions.

### Negative

- **Potential governance gaps**: A resource could violate a Config rule but
  not be blocked by an SCP (or vice versa). Alignment between preventive
  and detective layers requires discipline.

- **Duplicate coverage decisions**: Some controls exist in both layers
  (e.g., IMDSv2 is enforced by SCP and checked by Config). This is
  intentional defense-in-depth but adds maintenance cost.

- **No single source of truth**: There is no unified "governance policy"
  that generates both SCPs and Config rules. Each is authored independently.

## Alternatives Considered

### Single unified governance module

- **Pros**: One place to define all rules, consistent coverage
- **Cons**: Enormous blast radius, cannot deploy partially, mixes concerns
  with different operational characteristics, harder to test

Rejected because the failure modes of preventive and detective controls are
too different to safely combine.

### Config with auto-remediation

- **Pros**: Automatically fixes non-compliant resources
- **Cons**: Significant operational risk (may modify production resources
  unexpectedly), requires Lambda functions, complex IAM permissions, harder
  to reason about side effects

Rejected for v1. May be added as a separate optional layer in the future
after the detective baseline is proven stable.

### AWS Control Tower managed controls

- **Pros**: Unified UI, pre-built controls, automatic drift detection
- **Cons**: Less customizable, requires Control Tower enrollment (not
  implemented yet), abstracts away the underlying mechanisms

Deferred. Control Tower integration may be explored in a future phase. The
current approach uses the same underlying AWS services that Control Tower
would configure, making future migration straightforward.

## Related Decisions

- **ADR-001**: Monorepo structure supports independent module directories
- **ADR-002**: SCP targeting model keeps SCP module decoupled from org module
- **This ADR**: Config module kept decoupled from SCP module
