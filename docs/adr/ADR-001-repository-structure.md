# ADR-001: Repository Structure

## Status

Accepted

## Date

2026-08-18

## Context

This project implements an AWS landing zone platform using Terraform. The
codebase will grow to include multiple reusable modules, per-account deployment
configurations, governance policies, tests, and CI/CD definitions.

We need a repository structure that:

- Clearly separates reusable logic from deployment-specific configuration
- Allows independent deployment of each account/layer without coupling
- Supports incremental growth without requiring restructuring
- Makes the codebase navigable for reviewers and collaborators
- Enables targeted CI validation (only test what changed)

The two primary alternatives considered were a monorepo and a multi-repo
approach.

## Decision

Use a **monorepo** with the following top-level layout:

```
modules/          # Reusable Terraform modules (no provider/backend config)
environments/     # Per-account deployment compositions (provider + backend + module calls)
policies/         # OPA/Rego policies for plan validation via Conftest
tests/            # Validation fixtures and integration tests
scripts/          # Developer workflow scripts
docs/             # Documentation and ADRs
```

### Key design rules

1. **Modules are pure logic.** They accept variables, produce outputs, and
   contain no `provider`, `backend`, or `terraform_remote_state` blocks.

2. **Environments are compositions.** Each `environments/{account}/{layer}/`
   directory configures providers, backends, and composes modules with
   account-specific variables.

3. **Each environment directory is independently deployable.** Running
   `terraform init` and `terraform apply` in any environment directory must
   work without requiring other directories to be initialized first.

4. **Cross-environment references use data sources at runtime**, not
   compile-time coupling. For example, a workload VPC reads the Transit
   Gateway ID via `terraform_remote_state` data source, but does not import
   the network module directly.

5. **Policies are separate from infrastructure.** Governance rules in
   `policies/` are tested independently and executed against plan JSON
   outputs.

## Consequences

### Positive

- Single repository to clone, search, and review
- Atomic commits can span modules and their consumers for coordinated changes
- Shared CI pipeline with targeted execution based on changed paths
- Easier onboarding — one place to understand the entire platform
- Module versioning is implicit via Git history (no registry overhead for v1)

### Negative

- Repository will grow large over time; requires discipline in organization
- CI must be path-aware to avoid running all validations on every change
- No enforced module versioning — breaking changes require careful review
- All team members need access to the full repo (acceptable for a personal
  portfolio project)

## Alternatives Considered

### Multi-repo (one repo per module + one per account)

- **Pros:** Strong isolation, independent versioning, granular access control
- **Cons:** High overhead for a portfolio project, cross-repo coordination
  complexity, harder to review holistically, requires a module registry

Rejected because the operational overhead outweighs benefits at this project
scale, and holistic reviewability is a priority for a portfolio piece.

### Flat structure (all .tf files in root)

- **Pros:** Simple, no directory navigation
- **Cons:** Does not scale, no separation of concerns, cannot deploy
  accounts independently, mixes reusable logic with configuration

Rejected because it cannot support multi-account architecture.

### Terraform workspaces for environment separation

- **Pros:** Less directory duplication, single configuration with variable
  switching
- **Cons:** Shared state backend, blast radius of misconfiguration spans
  environments, workspace name becomes implicit context that is easy to
  forget, poor fit for fundamentally different account configurations

Rejected because directory-based separation provides explicit, visible, and
safe isolation between accounts.
