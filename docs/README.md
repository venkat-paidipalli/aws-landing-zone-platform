# Documentation

## Architecture

| Document | Description |
|----------|-------------|
| [Platform Overview](architecture/platform-overview.md) | End-to-end architecture explanation |
| [Multi-Account Reference](architecture/multi-account-reference.md) | OU hierarchy, accounts, security layers, networking |
| [Control Tower Integration](architecture/control-tower-integration.md) | CT vs Terraform ownership boundaries |
| [CI/CD Quality Gates](architecture/ci-cd-quality-gates.md) | Pipeline design and gate details |

## Governance

| Document | Description |
|----------|-------------|
| [Control Ownership Matrix](governance/control-ownership-matrix.md) | 18-control ownership mapping |

## Architecture Decision Records

| ADR | Decision |
|-----|----------|
| [ADR Index](adr/README.md) | Full list of all ADRs |

## Portfolio

| Document | Description |
|----------|-------------|
| [Interview Guide](portfolio/interview-guide.md) | Quick reference for discussing this project |

## Module Documentation

Each module has its own README:

| Module | Path |
|--------|------|
| Organization | [modules/organization/README.md](../modules/organization/README.md) |
| SCP | [modules/scp/README.md](../modules/scp/README.md) |
| Config | [modules/config/README.md](../modules/config/README.md) |
| GuardDuty | [modules/guardduty/README.md](../modules/guardduty/README.md) |
| Security Hub | [modules/security-hub/README.md](../modules/security-hub/README.md) |
| Log Archive | [modules/log-archive/README.md](../modules/log-archive/README.md) |
| CloudTrail | [modules/cloudtrail/README.md](../modules/cloudtrail/README.md) |
| VPC | [modules/vpc/README.md](../modules/vpc/README.md) |
| VPC IPAM | [modules/vpc-ipam/README.md](../modules/vpc-ipam/README.md) |
| Identity Center | [modules/identity-center/README.md](../modules/identity-center/README.md) |
