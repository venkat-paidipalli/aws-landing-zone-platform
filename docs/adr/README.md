# Architecture Decision Records

## Index

| ADR | Title | Status | Decision |
|-----|-------|--------|----------|
| [ADR-001](ADR-001-repository-structure.md) | Repository Structure | Accepted | Monorepo with modules/, environments/, policies/, tests/ |
| [ADR-002](ADR-002-scp-targeting-model.md) | SCP Targeting Model | Accepted | Logical path → target ID map for loose coupling |
| [ADR-003](ADR-003-preventive-vs-detective-controls.md) | Preventive vs Detective Controls | Accepted | Independent SCP and Config modules |
| [ADR-004](ADR-004-account-security-vs-organization-security.md) | Account vs Organization Security | Accepted | Account-level first, org-admin separately |
| [ADR-005](ADR-005-security-findings-aggregation-boundary.md) | Security Findings Aggregation | Accepted | Account-level SecurityHub, org aggregation later |
| [ADR-006](ADR-006-centralized-audit-logging-boundary.md) | Centralized Audit Logging | Accepted | Separate log storage from audit collection |
| [ADR-007](ADR-007-network-addressing-and-vpc-boundary.md) | Network Addressing and VPC | Accepted | IPAM planning, VPC provisioning, TGW connectivity as 3 layers |
| [ADR-008](ADR-008-identity-and-access-boundary.md) | Identity and Access | Accepted | Identity source separate from permission provisioning |
| [ADR-009](ADR-009-environment-composition-boundary.md) | Environment Composition | Accepted | Modules stay independent; environments own wiring |
| [ADR-010](ADR-010-control-tower-ownership-boundary.md) | Control Tower Ownership | Accepted | CT and Terraform use explicit resource ownership boundaries |
| [ADR-011](ADR-011-ci-security-quality-gates.md) | CI Security Quality Gates | Accepted | Every change must pass 6 automated validation gates |

## Format

Each ADR follows the structure:
- **Status**: Accepted / Proposed / Deprecated
- **Date**: When the decision was made
- **Context**: Why the decision was needed
- **Decision**: What was decided
- **Consequences**: Positive and negative outcomes
- **Alternatives Considered**: What was rejected and why
