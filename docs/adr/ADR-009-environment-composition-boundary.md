# ADR-009: Environment Composition Boundary

## Status

Accepted

## Date

2026-08-18

## Context

The platform has 10 reusable modules. Each is independently testable and
deployable. However, a landing zone requires these modules to work together
with specific wiring, configuration, and policy decisions.

We need to decide where integration logic lives.

## Decision

**Reusable modules stay independent. Environment compositions own all wiring.**

### Boundary Rules

| Concern | Owned By |
|---------|----------|
| Resource creation logic | Modules |
| Input validation | Modules |
| Default values | Modules |
| Cross-module wiring | Environment composition |
| Policy targeting decisions | Environment composition |
| Account-specific configuration | Environment composition |
| CIDR allocation | Environment composition |
| Identity assignments | Environment composition |

### Composition Pattern

```
environments/<name>/
├── locals.tf      → all configuration centralized
├── main.tf        → module instantiation + output wiring
├── outputs.tf     → architecture summaries
└── tests/         → composition-level assertions
```

Key principle: Modules produce outputs. Environments consume outputs and
feed them as inputs to other modules.

```hcl
# Module A produces
output "account_ids" { ... }

# Environment wires to Module B
module "identity_center" {
  assignments = {
    x = { target_account_id = module.organization.account_ids["dev"] }
  }
}
```

## Consequences

### Positive

- **Modules remain reusable**: No environment-specific logic pollutes modules.
  The same module works in different compositions.

- **Composition is explicit**: All wiring is visible in one place. Reviewers
  can see the full architecture by reading the environment's main.tf.

- **Independent testing preserved**: Module tests validate resource creation.
  Environment tests validate wiring and architecture.

- **Policy decisions are visible**: SCP targeting, CIDR allocation, and
  assignment mappings are explicit composition decisions, not hidden in
  module internals.

- **Multiple environments possible**: Different compositions (dev, staging,
  prod, reference) can use the same modules with different wiring.

### Negative

- **Composition complexity**: The environment main.tf grows as more modules
  are composed. Requires discipline in local organization.

- **Duplication risk**: Multiple environments may duplicate similar wiring.
  Addressed via shared locals or wrapper modules (future).

- **No enforcement**: Nothing prevents someone from tight-coupling modules.
  Relies on team discipline and code review.

## Alternatives Considered

### Modules directly reference each other

```hcl
module "scp" {
  organization = module.organization  # tight coupling
}
```

Rejected — makes modules untestable independently and creates implicit
dependency chains.

### Monolithic root module

All resources in one large configuration with no module boundaries.

Rejected — unscalable, no reuse, no independent testing.

### Terragrunt dependency management

External tool manages cross-module dependencies.

Deferred — adds toolchain complexity. Native Terraform composition is
sufficient for the current scope.

## Related Decisions

- **ADR-001**: Monorepo with modules/ and environments/ separation
- **ADR-002**: SCP targeting via logical path map (loose coupling)
- **ADR-006**: Log storage separate from collection (composition wires them)
- **ADR-007**: IPAM separate from VPC (environment allocates CIDRs)
- **ADR-008**: Identity source separate from authorization (environment provides principals)
