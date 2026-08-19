# Control Ownership Matrix

## Purpose

This document maps every governance control to its owner, implementation layer, and integration status. It serves as the authoritative reference for understanding which controls are managed by Terraform modules in this repository versus those managed (or expected to be managed) by AWS Control Tower.

## Matrix

| Control/Capability | Control Type | Owner | Implementation Layer | Target Scope | Current Status | Future CT Integration |
|--------------------|-------------|-------|---------------------|--------------|----------------|----------------------|
| Root user restrictions | Preventive | Terraform | `modules/scp` | Workloads/Infra/Sandbox | Implemented | CT may add mandatory control |
| Region restrictions | Preventive | Terraform | `modules/scp` | Workloads/Sandbox | Implemented | CT has region deny control |
| IMDSv2 requirement | Preventive | Terraform | `modules/scp` | Workloads | Implemented | Custom (CT doesn't include) |
| CloudTrail (account) | Detective/Audit | Terraform | `modules/cloudtrail` | Per-account | Implemented | CT creates org trail (replaces) |
| CloudTrail (org) | Audit | Control Tower | CT landing zone | Organization | Reference only | CT owns |
| AWS Config recorder | Detective | Terraform | `modules/config` | Per-account | Implemented | CT creates baseline recorder |
| Config custom rules | Detective | Terraform | `modules/config` | Per-account | Implemented | Supplements CT |
| GuardDuty (account) | Detective | Terraform | `modules/guardduty` | Per-account | Implemented | CT may enable org-wide |
| GuardDuty (org admin) | Detective | Control Tower/Security | Future module | Organization | Reference only | Security account delegated admin |
| Security Hub (account) | Detective | Terraform | `modules/security-hub` | Per-account | Implemented | CT enables with standards |
| Security Hub (org admin) | Detective | Control Tower/Security | Future module | Organization | Reference only | Security account delegated admin |
| S3 public access denied | Preventive | Both | SCP + Config rule | Organization | Implemented | CT has equivalent |
| Log archive protection | Storage | Terraform | `modules/log-archive` | Log Archive acct | Implemented | CT has own log archive |
| Network addressing (IPAM) | Network | Terraform | `modules/vpc-ipam` | Network acct | Implemented | Platform responsibility |
| VPC provisioning | Network | Terraform | `modules/vpc` | Per-account | Implemented | Platform responsibility |
| IAM access (permission sets) | Identity | Terraform | `modules/identity-center` | Cross-account | Implemented | Shared with CT |
| Account provisioning | Lifecycle | Control Tower/AFT | Account Factory | Organization | Reference only | CT/AFT owns |
| Account enrollment | Lifecycle | Control Tower | CT console/API | Per-OU | Reference only | CT owns |

## Ownership Legend

| Owner | Description |
|-------|-------------|
| **Terraform** | Managed by this repository's modules. Full lifecycle (create, update, destroy) in Terraform state. |
| **Control Tower** | Managed by AWS Control Tower. Not deployed in this repository — documented for future integration. |
| **Both** | Shared responsibility with clear boundaries. Terraform implements custom controls; CT provides baseline equivalent. |
| **Reference only** | Documented for architectural completeness but not implemented in any module. |

## Integration Notes

When Control Tower is deployed, some Terraform controls become supplementary rather than primary. The key principle is:

> **Control Tower provides the baseline; Terraform provides customization beyond that baseline.**

### Transition Guidelines

1. **Controls that CT replaces** — Account-level CloudTrail becomes optional when CT org trail is active. The Terraform module remains available for supplementary account-level trails but is no longer the primary audit mechanism.

2. **Controls that supplement CT** — Custom Config rules, custom SCPs (IMDSv2, region deny beyond CT scope), and platform-specific detective controls continue to operate alongside CT baseline.

3. **Controls with shared ownership** — S3 public access deny exists as both an SCP (preventive) and a Config rule (detective). CT may provide its own version. The platform team must audit for duplication and retire redundant Terraform controls.

4. **Controls unaffected by CT** — Networking (IPAM, VPC), platform identity (custom permission sets), and log archive (additional storage) remain fully Terraform-owned regardless of CT adoption.

### Conflict Resolution

When a conflict exists between a Terraform-managed control and a CT-managed control:

- CT takes precedence for resources it owns
- Terraform controls must be evaluated for retirement or modification
- The platform team documents the resolution in an ADR
- No Terraform resource should attempt to manage or override a CT-owned resource
