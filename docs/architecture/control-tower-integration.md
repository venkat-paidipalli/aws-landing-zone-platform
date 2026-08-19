# Control Tower Integration Architecture

## Overview

This document describes how the existing Terraform landing-zone modules integrate with AWS Control Tower. Control Tower is **not deployed** in this repository — this is architecture documentation that maps the responsibility boundaries between Control Tower (as the AWS-native governance layer) and the Terraform modules in this repository.

The purpose is to ensure that when Control Tower is adopted, the existing Terraform modules can coexist without conflict, duplication, or drift.

## Responsibility Split

| Concern | Owner | Notes |
|---------|-------|-------|
| Landing zone governance framework | Control Tower | Provides baseline guardrails and account governance |
| OU structure registration | Control Tower (enrollment) | OUs are registered/governed via CT |
| Mandatory preventive/detective controls | Control Tower | CT-managed SCPs and Config rules |
| Custom SCPs beyond CT scope | Terraform (`modules/scp`) | Region deny, IMDSv2, custom preventive controls |
| Account provisioning | Control Tower Account Factory / AFT | Account creation and OU placement |
| Account security baseline (Config, GuardDuty, SecurityHub) | Terraform modules | Per-account security services configuration |
| Networking (IPAM, VPC, TGW) | Terraform modules | Platform networking responsibilities |
| Permission sets and assignments | Terraform (`modules/identity-center`) | SSO permission sets and account assignments |
| Workload/platform configuration | Terraform environments | Environment-specific composition |
| Log archive bucket configuration | Terraform (`modules/log-archive`) | Additional log storage beyond CT log archive |
| Organization CloudTrail | Control Tower | CT creates and manages the organization trail |
| CI/CD pipeline | Platform team (GitHub Actions) | Deployment automation |

## Conceptual Architecture Flow

```
┌──────────────────┐     ┌───────────────────┐     ┌──────────────────┐
│ AWS Organizations│────▶│ AWS Control Tower  │────▶│  Governed OUs    │
└──────────────────┘     └───────────────────┘     └────────┬─────────┘
                                                            │
                                                            ▼
                                                 ┌─────────────────────┐
                                                 │ Account provisioning │
                                                 │    / enrollment      │
                                                 └────────┬────────────┘
                                                          │
                                                          ▼
                                              ┌────────────────────────┐
                                              │ Account baseline       │
                                              │ automation             │
                                              └────────┬───────────────┘
                                                       │
                                                       ▼
                                            ┌──────────────────────────┐
                                            │ Terraform platform       │
                                            │ modules                  │
                                            └────────┬─────────────────┘
                                                     │
                                                     ▼
                                            ┌──────────────────────────┐
                                            │ Workload resources       │
                                            └──────────────────────────┘
```

## Governed OU Model

The following OUs would be registered with Control Tower for governance:

| OU | Governed | Notes |
|----|----------|-------|
| Security | Yes (mandatory) | CT requires governance of the Security OU |
| Infrastructure | Yes | Network, shared services accounts |
| Workloads | Yes | Parent OU for environment sub-OUs |
| Workloads/NonProd | Yes | Development and staging workloads |
| Workloads/Prod | Yes | Production workloads with strict controls |
| Sandbox | Yes | Governed with relaxed controls for experimentation |
| Suspended | **NOT governed** | Deny-all SCP applied, quarantine only — no CT enrollment |

The Suspended OU is intentionally excluded from CT governance. Its purpose is to isolate compromised or decommissioned accounts using a blanket deny SCP. CT enrollment would conflict with this quarantine model.

## Account Lifecycle

The full account lifecycle in a Control Tower environment:

1. **Request** — Team submits account request with metadata (name, OU, owner, cost center)
2. **Review** — Platform team reviews and approves request
3. **Account Factory/AFT** — Account Factory (or AFT) provisions the account
4. **Creation** — AWS account is created in the organization
5. **CT Enrollment** — Control Tower enrolls the account in the target OU
6. **CT Baseline Controls** — CT applies mandatory guardrails (SCPs, Config rules, CloudTrail)
7. **Terraform Account Baseline** — Terraform applies security modules (GuardDuty, SecurityHub, custom Config rules)
8. **Identity Assignments** — Terraform assigns permission sets via Identity Center
9. **Networking** — Terraform provisions VPC, IPAM allocation, connectivity
10. **Application Onboarding** — Workload teams deploy into the baselined account

## Account Factory for Terraform (AFT) Boundary

Account Factory for Terraform (AFT) is a **future extension** that would automate account provisioning through a Terraform-native pipeline managed by Control Tower.

### Integration Points

| Integration Point | Description |
|-------------------|-------------|
| Account request metadata | Name, email, OU, tags submitted via AFT request repo |
| OU placement | AFT places accounts in the correct governed OU |
| Account tags | Cost center, environment, owner tags applied at creation |
| SSO assignments | AFT can trigger permission set assignments post-creation |
| Network configuration | AFT customizations can invoke network module |
| Security baseline | AFT global customizations apply security modules |
| Customizations | AFT account-level and OU-level customizations |

> **Status: NOT implemented.** AFT adoption is a future milestone. This section documents the expected integration boundary for planning purposes.

## Control Tower Controls vs Custom SCPs

| Control Type | Owner | Examples | Mechanism |
|--------------|-------|----------|-----------|
| Preventive (mandatory) | Control Tower | Deny root user actions, require MFA | SCP |
| Preventive (custom) | Terraform | Deny unapproved regions, require IMDSv2 | SCP |
| Detective (mandatory) | Control Tower | CloudTrail enabled, Config enabled | Config rule |
| Detective (custom) | Terraform | Encrypted volumes, SSM managed instances | Config rule |
| Proactive | Control Tower | Future capability | CloudFormation hooks |

### Coexistence Principles

Custom SCPs managed by Terraform must be evaluated against CT-managed policies to avoid:

- **Duplicate enforcement** — Applying the same deny twice adds complexity without security benefit
- **Conflicting logic** — A Terraform SCP that allows something CT denies (or vice versa) creates confusion
- **Upgrade interference** — CT updates may add controls that overlap with existing Terraform SCPs

When CT is deployed, the platform team must audit existing Terraform SCPs against CT's control catalog and retire any that become redundant.

## CloudTrail / Config Ownership

Control Tower creates its own organization trail and Config rules as part of the landing zone baseline. Our Terraform modules provide **additional** configuration beyond the CT baseline.

### In a Control Tower environment:

| Service | CT Responsibility | Terraform Responsibility |
|---------|-------------------|--------------------------|
| CloudTrail (org) | CT owns the organization trail, delivers to CT-managed bucket | Our `cloudtrail` module becomes **OPTIONAL** for additional account-level trails |
| Config recorder | CT owns the baseline Config recorder | Our `config` module adds **CUSTOM** rules beyond CT baseline |
| Log archive | CT has its own log archive account/bucket | Our `log-archive` module provides **ADDITIONAL** storage for platform-specific logs |

### Key distinction:

- CT-managed trails and Config rules are **hands-off** — Terraform must not attempt to manage them
- Terraform modules layer additional detective controls on top of the CT baseline
- If CT provides equivalent coverage, the Terraform resource becomes optional or is retired

## Identity Center Ownership

Control Tower integrates with IAM Identity Center (formerly AWS SSO) and may create baseline permission sets during landing zone setup.

### Ownership Model

- **Control Tower** may create: `AWSAdministratorAccess`, `AWSReadOnlyAccess`, and other CT-managed sets
- **Terraform** manages: Platform-specific permission sets (`PlatformAdmin`, `NetworkAdmin`, `SecurityAuditor`, `DeveloperAccess`, etc.)
- **Boundary rule**: Terraform-managed permission sets must not conflict with or modify CT-created sets

Our `modules/identity-center` module manages permission sets and assignments that are explicitly approved by the platform team and do not overlap with CT-provided defaults.

## Organization Module Modes

The landing zone modules support different operating modes depending on whether Control Tower is present:

### Greenfield (no CT)

- Terraform creates the AWS Organization
- Terraform creates OUs and manages OU structure
- Terraform provisions accounts (or documents manual creation)
- Full ownership of all organizational resources

### Existing CT Environment (future adoption mode)

- Terraform **consumes** the existing organization via `data` sources
- Terraform **consumes** existing OUs via `data` sources or `terraform import`
- Terraform does NOT create or modify CT-owned organizational resources
- Terraform layers additional controls and services on top of CT baseline

> This "adoption mode" is documented as a future capability. When CT is deployed, modules will need conditional logic or separate configurations to operate in read-only mode for CT-owned resources.

## Security Services Future Model

### Current State: Account-Level

Each account independently runs GuardDuty, SecurityHub, and Config with findings stored locally.

### Future State: Organization-Level with CT Coordination

```
┌─────────────────────────────┐
│   Security Tooling Account  │
│                             │
│  ┌───────────────────────┐  │
│  │ GuardDuty delegated   │  │
│  │ administrator         │  │
│  └───────────┬───────────┘  │
│              │              │
│  ┌───────────────────────┐  │
│  │ SecurityHub delegated │  │
│  │ administrator         │  │
│  └───────────┬───────────┘  │
│              │              │
└──────────────┼──────────────┘
               │
               ▼
┌──────────────────────────────┐
│       Member Accounts        │
│  (auto-enabled via org)      │
└──────────────────────────────┘
```

- **Current** = Account-level enablement via Terraform modules
- **Future** = Organization-level with Security Tooling account as delegated admin, coordinated with CT

## Logging Future Model

### Current State: Account-Level CloudTrail

Each account has its own trail delivering to local or centralized S3 bucket.

### Future State: Organization-Level with CT

```
┌────────────────────┐     ┌──────────────────────────┐
│  Member Accounts   │────▶│ Organization audit events │
└────────────────────┘     └────────────┬─────────────┘
                                        │
                                        ▼
                           ┌──────────────────────────┐
                           │ CT / Organization logging │
                           │ (org trail)               │
                           └────────────┬─────────────┘
                                        │
                                        ▼
                           ┌──────────────────────────┐
                           │  Log Archive Account     │
                           │  (CT-managed bucket +    │
                           │   platform bucket)       │
                           └──────────────────────────┘
```

- CT manages the organization trail and its delivery to the Log Archive account
- The platform `log-archive` module manages additional storage for platform-specific logs
- Account-level trails (current implementation) become optional supplementary trails

## Networking Relationship

Control Tower does **NOT** replace networking responsibilities. The following remain exclusively platform Terraform responsibilities regardless of CT adoption:

- **IPAM** — IP address management and pool allocation (`modules/vpc-ipam`)
- **VPC** — Virtual Private Cloud provisioning and configuration (`modules/vpc`)
- **Transit Gateway** — Future cross-account/cross-VPC connectivity
- **Route 53** — DNS management and resolution
- **Network Firewall** — Future centralized egress filtering

CT provides no networking automation. These modules operate independently of CT governance.

## Drift / Ownership Safety Rules

### Rules

1. **Terraform must NOT manage CT-owned resources** — Organization trail, CT Config rules, CT SCPs, CT IAM roles
2. **CT-created IAM roles are hands-off** — `AWSControlTower*` roles must never appear in Terraform state
3. **CT-managed CloudTrail is hands-off** — The organization trail created by CT is not a Terraform resource
4. **CT-managed Config rules are hands-off** — CT detective controls are not managed by Terraform
5. **Custom resources must be clearly namespaced** — Use prefixes like `platform-`, `custom-` to distinguish from CT resources
6. **Terraform must not attempt to modify CT landing zone settings** — Landing zone configuration is CT console/API only
7. **If CT repairs/updates, Terraform must not revert changes** — CT self-healing must take precedence

### Risks

| Risk | Description | Mitigation |
|------|-------------|------------|
| Drift | CT repairs a resource that Terraform also manages | Clear ownership boundaries, lifecycle ignore rules |
| Repair operations | CT detects drift and reverts a Terraform change | Never manage CT-owned resources in Terraform |
| Terraform reverting CT | `terraform apply` overwrites a CT update | Exclude CT resources from state, use data sources |
| Failed upgrades | CT landing zone upgrade fails due to Terraform conflicts | Test CT upgrades in non-prod, audit resource overlap |
| Governance conflicts | Terraform SCP conflicts with CT SCP | Pre-deployment audit of combined SCP effect |

### Best Practices

- Use `lifecycle { ignore_changes }` for any resource that CT might modify
- Prefer `data` sources over `resource` blocks for CT-owned infrastructure
- Maintain a clear inventory of CT-owned vs Terraform-owned resources
- Run regular audits comparing Terraform state against actual AWS state
- Document any shared resources with explicit ownership notes
