# Reference Landing Zone Environment

## Purpose

This is a **reference composition** that demonstrates how all platform modules
wire together into a coherent multi-account AWS landing zone. It validates
structurally but does **not** deploy to AWS.

## What This Composition Demonstrates

- Organization structure (7 OUs, 8 member accounts)
- Preventive governance (3 SCPs with targeted attachment)
- Centralized IP address management (IPAM with environment pools)
- Workload VPCs (4 VPCs with private/data subnets)
- Audit logging (S3 log archive + CloudTrail)
- Detective security (Config rules + GuardDuty + Security Hub)
- Identity and access (5 permission sets, 8 group-based assignments)

## Architecture Layers

```
Layer 1: Organization     → OUs, accounts, structure
Layer 2: Governance       → SCPs (preventive controls)
Layer 3: Networking       → IPAM pools, VPCs, subnets
Layer 4: Logging          → S3 archive, CloudTrail
Layer 5: Security         → Config, GuardDuty, Security Hub
Layer 6: Identity         → Permission sets, account assignments
```

## Module Composition Pattern

```
locals.tf           → centralized configuration
        ↓
main.tf             → module instantiation + wiring
        ↓
module outputs      → feed into downstream modules
        ↓
outputs.tf          → architecture summaries
```

Key wiring relationships:
- `module.organization.organizational_unit_ids` → `module.scp.target_ids`
- `module.organization.account_ids` → `module.identity_center.assignments`
- `module.log_archive.bucket_name` → `module.cloudtrail.s3_bucket_name`

## Account Responsibility Model

| Account | OU | Responsibility |
|---------|-----|---------------|
| lz-security-tooling | Security | Future GuardDuty/SecurityHub delegated admin |
| lz-log-archive | Security | Centralized audit log storage |
| lz-network | Infrastructure | IPAM, future TGW/DNS/inspection |
| lz-shared-services | Infrastructure | Common platform services |
| lz-sandbox | Sandbox | Isolated experimentation |
| lz-development | Workloads/NonProd | Dev workloads |
| lz-staging | Workloads/NonProd | Pre-production validation |
| lz-production | Workloads/Prod | Production workloads |

## SCP Targeting Strategy

| Policy | Targets | Rationale |
|--------|---------|-----------|
| deny-root-user | Infrastructure, Workloads/*, Sandbox | Security OU excluded for incident response |
| deny-unapproved-regions | Workloads/*, Sandbox | Infrastructure needs global ops |
| require-imdsv2 | Workloads/* only | Where EC2 instances actually run |

## What Is NOT Implemented Yet

- Organization-wide CloudTrail (org trail)
- Delegated administrator for GuardDuty/SecurityHub/Config
- Transit Gateway hub-spoke connectivity
- Route 53 Resolver centralized DNS
- Network Firewall / inspection VPC
- Control Tower enrollment
- External IdP / SCIM federation
- Cross-account provider aliases (requires real credentials)
- NAT Gateways
- VPC Flow Logs (destination not created)

## Usage

```bash
# Validate structure (no AWS credentials needed)
terraform -chdir=environments/reference init -backend=false
terraform -chdir=environments/reference validate
terraform -chdir=environments/reference test
```

## Control Tower Integration

The `control-tower/` subdirectory contains architecture metadata documenting
how this landing zone integrates with AWS Control Tower:

- Governed OU declarations (6 governed, Suspended excluded)
- 7-layer baseline model with CT as layer 1
- Module compatibility assessment for all 10 modules
- Ownership boundary declarations (CT-owned vs Terraform-owned)
- 20 architecture boundary tests

See `docs/architecture/control-tower-integration.md` for the full strategy.

## Important

- All values are FICTIONAL (emails, account IDs, principal IDs)
- No real AWS deployment occurs
- Mock provider credentials prevent API calls
- This is a portfolio demonstration of composition architecture
