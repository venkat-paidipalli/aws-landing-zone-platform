# AWS Landing Zone Platform

A production-style AWS landing zone platform built with Terraform, demonstrating
senior cloud/platform engineering concepts for multi-account governance,
security, networking, and operational excellence.

## Purpose

This is a **personal portfolio project** designed to showcase end-to-end AWS
landing zone architecture using Infrastructure as Code. It demonstrates how a
platform engineering team would design, govern, and operate a multi-account AWS
environment from scratch.

**This project does not contain real AWS accounts, credentials, or live
deployments.** All account IDs, names, and configurations use fictional example
values. The platform is designed to be validated locally without requiring AWS
access.

## Architecture Overview

The platform implements a multi-account AWS strategy with:

- **AWS Organizations** with organizational units for security, infrastructure,
  workloads, and sandbox isolation
- **Service Control Policies** for preventive guardrails across the organization
- **Centralized security** via GuardDuty, Security Hub, and AWS Config with
  delegated administration
- **Centralized logging** with organization-wide CloudTrail and log aggregation
- **IAM Identity Center** for federated access with permission sets
- **Hub-spoke networking** using Transit Gateway, VPC IPAM, and Route 53
  Resolver
- **Governance automation** through tagging standards, Config rules, and policy
  enforcement

### Account Strategy

| Account | Purpose | OU |
|---------|---------|-----|
| lz-management | Organization root, billing, SCPs | Root |
| lz-security | GuardDuty/Security Hub admin | Security |
| lz-log-archive | Centralized audit logs | Security |
| lz-network | Transit Gateway, DNS, IPAM | Infrastructure |
| lz-shared-services | CI/CD tooling, shared resources | Infrastructure |
| lz-sandbox | Experimentation | Sandbox |
| lz-development | Dev workloads | Workloads > NonProd |
| lz-staging | Pre-production | Workloads > NonProd |
| lz-production | Production workloads | Workloads > Prod |

### OU Hierarchy

```
Root
├── Security
├── Infrastructure
├── Workloads
│   ├── NonProd
│   └── Prod
├── Sandbox
└── Suspended
```

## Planned Capabilities

- [x] Organization structure with OUs and accounts
- [x] Service Control Policies (preventive guardrails)
- [ ] Centralized CloudTrail (organization trail)
- [x] AWS Config recording and managed rules
- [x] GuardDuty account-level threat detection
- [x] Security Hub account-level compliance
- [x] Secure audit log storage (S3)
- [x] Account-level CloudTrail baseline
- [x] VPC baseline with configurable subnets
- [x] VPC IPAM centralized address management
- [x] IAM Identity Center permission sets and assignments
- [ ] Transit Gateway hub-spoke networking
- [ ] VPC IPAM for IP address management
- [ ] Route 53 Resolver for centralized DNS
- [ ] Tagging enforcement
- [ ] OPA/Rego policy validation
- [ ] CI/CD pipeline with security scanning

## Repository Structure

```
aws-landing-zone-platform/
├── modules/              # Reusable Terraform modules
│   ├── organization/     # AWS Organization, OUs, accounts (implemented)
│   │   └── tests/        # Native tests (mocked provider)
│   ├── scp/              # Service Control Policies (implemented)
│   │   └── tests/        # Native tests (mocked provider)
│   ├── config/           # AWS Config governance baseline (implemented)
│   │   └── tests/        # Native tests (mocked provider)
│   ├── guardduty/        # GuardDuty threat detection (implemented)
│   │   └── tests/        # Native tests (mocked provider)
│   ├── security-hub/    # Security Hub compliance (implemented)
│   │   └── tests/        # Native tests (mocked provider)
│   ├── log-archive/     # Secure S3 audit log storage (implemented)
│   │   └── tests/        # Native tests (mocked provider)
│   ├── cloudtrail/      # CloudTrail audit events (implemented)
│   │   └── tests/        # Native tests (mocked provider)
│   ├── vpc/             # VPC with subnets and routing (implemented)
│   │   └── tests/        # Native tests (mocked provider)
│   ├── vpc-ipam/        # Centralized IP address management (implemented)
│   │   └── tests/        # Native tests (mocked provider)
│   └── identity-center/ # IAM Identity Center permission sets (implemented)
│       └── tests/        # Native tests (mocked provider)
├── environments/         # Per-account deployment compositions
│   └── reference/       # Multi-account reference landing zone (implemented)
│       ├── tests/        # Composition tests (mocked provider)
│       └── control-tower/ # CT integration boundary metadata
│           └── tests/    # CT boundary tests
├── policies/             # OPA/Rego policies and SCP documents
│   └── scp/              # SCP JSON policy library
├── tests/                # Validation fixtures and tests
│   └── fixtures/
│       ├── minimal/      # Toolchain sanity check
│       ├── organization-interface/    # Full org module validation
│       ├── organization-invalid-inputs/  # Org validation failure cases
│       ├── scp-invalid-inputs/        # SCP validation failure cases
│       ├── organization-with-scp/     # Org + SCP integration
│       ├── config-interface/          # Config module validation
│       ├── config-invalid-inputs/     # Config validation failure cases
│       ├── guardduty-interface/       # GuardDuty module validation
│       ├── guardduty-invalid-inputs/  # GuardDuty validation failure cases
│       ├── security-hub-interface/    # Security Hub module validation
│       ├── security-hub-invalid-inputs/ # Security Hub failure cases
│       ├── log-archive-interface/     # Log archive module validation
│       ├── log-archive-invalid-inputs/ # Log archive failure cases
│       ├── cloudtrail-interface/      # CloudTrail module validation
│       ├── cloudtrail-invalid-inputs/ # CloudTrail failure cases
│       ├── logging-foundation/        # Log archive + CloudTrail integration
│       ├── vpc-interface/             # VPC module validation
│       ├── vpc-invalid-inputs/        # VPC failure cases
│       ├── vpc-ipam-interface/        # IPAM module validation
│       ├── vpc-ipam-invalid-inputs/   # IPAM failure cases
│       ├── networking-foundation/     # IPAM + VPC integration
│       ├── identity-center-interface/ # Identity Center validation
│       └── identity-center-invalid-inputs/ # Identity Center failures
├── scripts/              # Local validation and helper scripts
├── docs/                 # Documentation
│   ├── README.md          # Documentation index
│   ├── architecture/      # Architecture documents + Mermaid diagrams
│   ├── governance/        # Control ownership matrix
│   ├── portfolio/         # Interview guide
│   └── adr/              # Architecture Decision Records (11)
├── .terraform-version    # Pinned Terraform version (1.7.5)
├── .editorconfig         # Editor formatting standards
├── .gitignore            # VCS exclusions
├── .checkov.yml          # Security scanner configuration
├── .gitleaks.toml        # Secret scanner configuration
├── .github/
│   └── workflows/
│       └── terraform-ci.yml  # CI quality gate pipeline
├── Makefile              # Developer workflow targets
├── LICENSE               # MIT License
├── CONTRIBUTING.md       # Contribution guidelines
├── SECURITY.md           # Security policy
└── README.md             # This file
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7
- [tfenv](https://github.com/tfutils/tfenv) (recommended for version management)
- Git

### Optional (for future phases)

- [tflint](https://github.com/terraform-linters/tflint)
- [tfsec](https://github.com/aquasecurity/tfsec) or [checkov](https://www.checkov.io/)
- [conftest](https://www.conftest.dev/)
- [infracost](https://www.infracost.io/)

## Quick Start

```bash
# Verify Terraform is installed
terraform version

# Run full quality gate (format + validate + tests)
make check

# Or run individual steps:
make fmt-check    # Check formatting
make validate     # Init + validate all fixtures
make test         # Run Terraform native tests (mocked provider)
```

On Windows (PowerShell):

```powershell
.\scripts\validate.ps1
```

No AWS credentials are required for any validation step.

## Implementation Status

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | Foundation (repo structure, CI, org module) | Complete |
| Phase 2 | Security & Identity | Not Started |
| Phase 3 | Networking | Not Started |
| Phase 4 | Workloads & Shared Services | Not Started |
| Phase 5 | Polish & Documentation | Not Started |

## CI/CD & Quality Gates

The repository includes a GitHub Actions CI pipeline that validates every
change without requiring AWS credentials:

| Gate | Tool | Purpose |
|------|------|---------|
| Format | `terraform fmt` | Consistent code style |
| Validate | `terraform validate` | Structural correctness |
| Test | `terraform test` | Behavioral assertions (155+ mocked tests) |
| Security | Checkov | Static security analysis |
| Secrets | gitleaks | Credential leak detection |
| Policy | OPA/Conftest | Governance rule enforcement |

```bash
# Run locally (Linux/macOS)
make check        # Format + validate + test
make check-all    # Full gate including security/policy/secrets

# Run locally (Windows)
.\scripts\validate.ps1
```

The pipeline is configured and ready for GitHub execution. No AWS deployment
occurs — validation only.

See `docs/architecture/ci-cd-quality-gates.md` for details.

## Control Tower Integration Strategy

This architecture is **Control Tower-ready** but does NOT deploy Control Tower:

- Clear ownership boundaries between CT and Terraform are documented
- Module compatibility is assessed (8 compatible, 1 optional-with-CT, 1 requires adjustment)
- Governance control ownership matrix maps 18 controls to their owner
- 7-layer baseline model defines execution ordering
- Drift and ownership safety rules prevent resource conflicts
- Account Factory for Terraform (AFT) integration is planned but not implemented

See `docs/architecture/control-tower-integration.md` and
`docs/governance/control-ownership-matrix.md` for details.

## Project Status

**Portfolio reference implementation — validated locally, not deployed to AWS.**

| Metric | Value |
|--------|-------|
| Terraform modules | 10 |
| Mocked test assertions | 155 |
| Architecture Decision Records | 11 |
| Validation fixtures | 23+ |
| Repository files | 185+ |
| CI quality gates | 6 |
| AWS credentials required | None |

Terraform native tests pass using `mock_provider`. Security tools (Checkov,
gitleaks, Conftest) are configured for CI execution and run locally when
installed. The first CI execution will occur after the initial GitHub push.

## Future Enhancements

Not implemented — documented for future development:

- Transit Gateway hub-spoke connectivity
- Route 53 Resolver centralized DNS
- Network Firewall / inspection VPC
- Organization-level security administration (delegated admin)
- Organization CloudTrail
- Account Factory for Terraform (AFT)
- Deployment pipeline (plan → approve → apply)
- Live AWS integration tests
- Multi-region deployment
- External IdP federation (Entra/Okta)

## Important Disclaimers

- This is a **personal portfolio project** for demonstration purposes only.
- **No real AWS accounts or credentials** are used or included.
- **No AWS resources are deployed** — all validation is local/structural.
- All account names, IDs, and configurations are **fictional examples**.
- This project was built from scratch and does not reuse code from any
  employer, client, or private repository.

## License

This project is provided as a portfolio demonstration. See individual files for
any applicable licensing.
