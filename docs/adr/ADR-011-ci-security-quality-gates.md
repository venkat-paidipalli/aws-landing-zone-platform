# ADR-011: CI Security and Quality Gates

## Status

Accepted

## Date

2026-08-18

## Context

Infrastructure-as-code repositories require automated validation to prevent
introducing misconfigurations, security vulnerabilities, exposed secrets,
or policy violations into the codebase.

The validation must work without cloud credentials to support:
- Open-source portfolio projects
- PR-based workflows without elevated permissions
- Fast feedback before deployment decisions

## Decision

**Every infrastructure change must pass automated structural, behavioral,
security, secret, and policy validation before merge.**

### Pipeline Gates

| Gate | Tool | Blocks Merge | AWS Required |
|------|------|:------------:|:------------:|
| Formatting | `terraform fmt` | Yes | No |
| Validation | `terraform validate` | Yes | No |
| Tests | `terraform test` (mocked) | Yes | No |
| Security | Checkov | Yes | No |
| Secrets | gitleaks | Yes | No |
| Policy | OPA/Conftest | Yes | No |

### Credential-Free Design

The entire CI pipeline operates without AWS credentials:
- `terraform validate` uses provider skip flags or mocked providers
- `terraform test` uses `mock_provider "aws" {}`
- Checkov analyzes Terraform source statically
- gitleaks analyzes git content patterns
- OPA/Conftest evaluates plan JSON or source patterns

### Security Scanning Strategy

- **Checkov**: Static analysis of Terraform configurations for CIS/AWS best practices
- **Minimal suppressions**: Only 6 skips, each with documented justification
- **No broad exclusions**: Every skip targets a specific, documented architectural decision

### Policy-as-Code

- **OPA/Rego policies**: Small, focused rule set (6 deny + 1 warn)
- **Security policies**: No public access without justification, no hard-coded keys
- **Governance policies**: No Control Tower resources, no org trails, tag requirements
- **Deterministic tests**: Each policy has corresponding test cases

### Secret Scanning

- **gitleaks**: Detects credential patterns in repository content
- **Allowlist**: Only mock-access-key-for-validation (clearly synthetic)
- **No real secrets**: Repository contains zero real credentials by design

## Consequences

### Positive

- **Shift-left security**: Issues caught before code review, not in production
- **Consistent enforcement**: Every PR gets the same checks regardless of reviewer
- **Documentation through tests**: 155+ tests document expected behavior
- **No credential risk**: Pipeline never handles real AWS credentials
- **Extensible**: Future gates (infracost, tflint) can be added incrementally

### Negative

- **Cannot validate runtime behavior**: Mocked tests don't catch API-level issues
- **False positives**: Checkov may flag intentional architectural decisions (mitigated by documented skips)
- **Tool availability**: Some gates (conftest, checkov) require tool installation for local runs
- **No plan validation**: Without real credentials, cannot verify plan accuracy

## Alternatives Considered

### No CI (manual validation only)

Rejected — inconsistent, error-prone, doesn't scale.

### Full deployment testing

Rejected for v1 — requires real AWS accounts, adds cost and complexity.
Future extension.

### Multiple overlapping scanners (tfsec + checkov + snyk)

Rejected — redundant findings, maintenance overhead, diminishing returns.
One well-configured scanner is sufficient for portfolio scope.

## Related Decisions

- **ADR-001**: Monorepo supports unified CI pipeline
- **ADR-010**: CT ownership boundary prevents CT resource creation (enforced by policy)
