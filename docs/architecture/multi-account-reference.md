# Multi-Account Landing Zone Reference Architecture

## Overview

This document describes the reference architecture implemented in
`environments/reference/`. It composes 10 independently testable Terraform
modules into a coherent AWS landing zone.

## OU Hierarchy

```
Root (management account - not managed as member)
├── Security
│   ├── lz-security-tooling  (future GuardDuty/SecurityHub delegated admin)
│   └── lz-log-archive       (centralized audit log storage)
├── Infrastructure
│   ├── lz-network           (IPAM, future TGW/DNS/inspection)
│   └── lz-shared-services   (common platform services)
├── Workloads
│   ├── NonProd
│   │   ├── lz-development   (dev workloads)
│   │   └── lz-staging       (pre-production)
│   └── Prod
│       └── lz-production    (production workloads)
├── Sandbox
│   └── lz-sandbox           (isolated experimentation)
└── Suspended                 (empty - for quarantined accounts)
```

## Account Responsibilities

| Account | OU | Current Role | Future Role |
|---------|-----|-------------|-------------|
| lz-security-tooling | Security | Security baseline | GuardDuty/SecurityHub delegated admin |
| lz-log-archive | Security | Audit log bucket | Org CloudTrail + Config log destination |
| lz-network | Infrastructure | IPAM pools | TGW, Route53 Resolver, inspection VPC |
| lz-shared-services | Infrastructure | Shared VPC | CI/CD, artifact repos, shared AMIs |
| lz-sandbox | Sandbox | Isolated VPC | Learning/experimentation (restricted) |
| lz-development | Workloads/NonProd | Dev VPC | Application development |
| lz-staging | Workloads/NonProd | Staging VPC | Pre-production validation |
| lz-production | Workloads/Prod | Prod VPC | Production workloads |

## Security Control Layers

```
┌─────────────────────────────────────────────────────────┐
│ Layer 1: PREVENTIVE (SCPs)                              │
│ ┌─────────────┐ ┌───────────────────┐ ┌──────────────┐ │
│ │ deny-root   │ │ deny-regions      │ │ require-     │ │
│ │ user        │ │ (us-east-1,       │ │ imdsv2       │ │
│ │             │ │  us-west-2 only)  │ │              │ │
│ └─────────────┘ └───────────────────┘ └──────────────┘ │
├─────────────────────────────────────────────────────────┤
│ Layer 2: DETECTIVE (per-account)                        │
│ ┌──────────┐ ┌────────────┐ ┌────────────────────────┐ │
│ │ AWS      │ │ Amazon     │ │ AWS Security Hub       │ │
│ │ Config   │ │ GuardDuty  │ │ (Foundational std)     │ │
│ │ (4 rules)│ │ (S3 prot)  │ │                        │ │
│ └──────────┘ └────────────┘ └────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│ Layer 3: AUDIT (per-account → centralized)              │
│ ┌────────────────────────────────────────────────────┐  │
│ │ CloudTrail → S3 Log Archive (versioned, encrypted) │  │
│ └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Networking / Address Plan

```
IPAM (us-east-1, us-west-2)
├── nonprod pool
│   ├── 10.10.0.0/16 → lz-development VPC
│   └── 10.20.0.0/16 → lz-staging VPC
├── prod pool
│   └── 10.30.0.0/16 → lz-production VPC
├── shared pool
│   ├── 10.40.0.0/16 → lz-shared-services VPC
│   └── 10.50.0.0/16 → lz-network VPC (future)
└── sandbox pool
    └── 10.60.0.0/16 → lz-sandbox VPC (future)
```

Each workload VPC uses private + data subnets across 2 AZs:
- `x.x.1.0/24` private-a, `x.x.2.0/24` private-b
- `x.x.11.0/24` data-a, `x.x.12.0/24` data-b

No IGW, no NAT, no public subnets. Connectivity via future Transit Gateway.

## Logging Model

```
Each Account:
  CloudTrail (multi-region, log validation)
        ↓
  S3 Log Archive Bucket
        ├── Versioning enabled (tamper protection)
        ├── AES256 encryption
        ├── TLS enforced
        └── Lifecycle: IA(90d) → Glacier(365d) → Expire(7yr)
```

Future: Organization trail from management account delivers all member
account events to the log-archive account's bucket.

## Identity / Access Model

```
Identity Source (future: Entra/Okta)
        ↓
IAM Identity Center (groups)
        ↓
Permission Sets:
  ├── ReadOnly        (PT1H)  → auditors
  ├── Developer       (PT4H)  → dev team
  ├── SecurityAudit   (PT1H)  → security team
  ├── NetworkAdmin    (PT4H)  → network team
  └── PlatformAdmin   (PT1H)  → platform team (with inline deny)
        ↓
Account Assignments:
  ├── Developers     → development, staging (NOT production)
  ├── Security team  → security-tooling, log-archive
  ├── Network team   → network
  ├── Platform admins → security-tooling, network
  └── Auditors       → production (read-only)
```

## Module Composition

| Module | Instance | Key Inputs From |
|--------|----------|-----------------|
| organization | 1 | locals |
| scp | 1 | organization.organizational_unit_ids |
| vpc-ipam | 1 | locals (CIDR plan) |
| vpc | 4 | locals (subnet templates) |
| log-archive | 1 | locals |
| cloudtrail | 1 | log_archive.bucket_name |
| config | 1 | locals (representative) |
| guardduty | 1 | locals (representative) |
| security-hub | 1 | locals |
| identity-center | 1 | organization.account_ids |

## Current Boundaries

What exists:
- Organization structure with SCPs
- Per-account security baselines
- Account-level CloudTrail to S3
- IPAM address planning
- Workload VPCs (private, isolated)
- Permission sets with group-based assignments

What does NOT exist yet:
- Cross-account connectivity (Transit Gateway)
- Centralized DNS (Route 53 Resolver)
- Organization-level security admin
- Organization CloudTrail
- Network inspection/egress filtering
- Control Tower enrollment
- External IdP federation
- Multi-region deployment

## Future Control Tower Integration

When Control Tower is adopted:
1. It manages OU structure (may replace organization module for enrolled OUs)
2. It provides built-in guardrails (supplements/replaces some SCPs)
3. It configures account baselines (Config, CloudTrail)
4. It manages Identity Center instance
5. Custom modules remain for platform-specific controls beyond CT scope
