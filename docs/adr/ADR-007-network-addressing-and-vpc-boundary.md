# ADR-007: Network Addressing and VPC Boundary

## Status

Accepted

## Date

2026-08-18

## Context

A multi-account landing zone requires predictable, non-overlapping IP address
space across all accounts and VPCs. Without centralized management:

- Teams allocate CIDRs ad-hoc, creating overlaps
- Transit Gateway routing breaks when CIDRs conflict
- VPC peering is impossible between overlapping address spaces
- Mergers/acquisitions add conflicting ranges

We need a strategy that separates:
1. Address planning (who owns which ranges)
2. VPC provisioning (how networks are built)
3. Connectivity (how VPCs communicate)

## Decision

Use **three independent layers** for network architecture:

```
Layer 1: VPC IPAM (address planning)
    ↓ documents/allocates CIDR ranges
Layer 2: VPC module (network provisioning)
    ↓ creates VPCs with allocated CIDRs
Layer 3: Transit Gateway (connectivity) [future]
    ↓ routes traffic between VPCs
```

### Module Boundaries

| Module | Responsibility | Not Responsible For |
|--------|---------------|-------------------|
| `vpc-ipam` | CIDR planning, pools, allocation tracking | VPC creation, routing |
| `vpc` | VPC, subnets, route tables, IGW | Address allocation, TGW |
| `transit-gateway` (future) | Cross-VPC routing, attachments | VPC creation, IPAM |

### Addressing Model

```
IPAM (10.0.0.0/8 supernet)
├── nonprod pool
│   ├── 10.1.0.0/16 → development VPC
│   └── 10.2.0.0/16 → staging VPC
├── prod pool
│   └── 10.3.0.0/16 → production VPC
├── shared-services pool
│   └── 10.4.0.0/16 → shared-services VPC
└── sandbox pool
    └── 10.5.0.0/16 → sandbox VPC
```

### Composition

The environment layer wires IPAM and VPC together:

```hcl
module "ipam" { ... }  # Defines pools and CIDRs

module "vpc" {
  vpc_cidr_block = "10.1.0.0/16"  # From IPAM allocation
  # ...
}
```

In v1, VPCs use static CIDRs that align with the IPAM pool plan.
In future iterations, VPCs can dynamically allocate from IPAM pools
using `ipv4_ipam_pool_id` on the `aws_vpc` resource.

## Consequences

### Positive

- **Overlap prevention**: IPAM documents the authoritative CIDR plan.
  Even without dynamic allocation, the plan prevents ad-hoc conflicts.

- **Environment separation**: Production and non-production use distinct
  address ranges, making routing policy enforcement simple.

- **Future Transit Gateway compatibility**: Non-overlapping CIDRs are a
  prerequisite for TGW routing. Planning this upfront avoids painful
  re-IP later.

- **Independent modules**: VPC module works with any CIDR (static or
  IPAM-allocated). IPAM module works without VPC creation. Each is
  testable alone.

- **Scalability**: Adding new accounts means allocating from existing pools.
  The IPAM tracks what's used and what's available.

### Negative

- **Static CIDRs in v1**: Without dynamic IPAM allocation, CIDRs must be
  coordinated manually. The IPAM pool serves as documentation rather than
  enforcement in this phase.

- **No runtime overlap detection**: Terraform cannot verify at plan time
  that a VPC CIDR doesn't overlap with CIDRs in other state files.

- **Two modules to configure**: Callers must configure both IPAM (planning)
  and VPC (provisioning) even though the IPAM doesn't auto-provision VPCs.

## Alternatives Considered

### Single VPC+IPAM module

- **Pros**: One module handles addressing and VPC creation
- **Cons**: Cannot test independently, mixes concerns, not reusable for
  accounts that need VPCs without IPAM (or IPAM without VPCs)

Rejected — violates separation of concerns.

### No IPAM (manual CIDR tracking)

- **Pros**: Simpler, fewer resources, cheaper (IPAM has cost)
- **Cons**: No audit trail, overlap risk, no pool-based allocation,
  spreadsheet-based tracking is error-prone

Rejected for a production platform — IPAM cost is justified by overlap
prevention and allocation governance.

### Dynamic IPAM allocation in v1

- **Pros**: Fully automated CIDR assignment
- **Cons**: More complex VPC module (needs IPAM pool ID input), harder
  to test with mocked providers, creates dependency between modules

Deferred — the addressing model is designed for dynamic allocation in
a future iteration. Static CIDRs in v1 reduce complexity while the
IPAM documents the plan.

## Future Architecture

1. **Transit Gateway** module connects VPCs via hub-spoke
2. **VPC module** gains optional `ipv4_ipam_pool_id` for dynamic allocation
3. **Route 53 Resolver** provides centralized DNS across VPCs
4. **Network Firewall** / inspection VPC for egress filtering
5. **RAM sharing** distributes IPAM pools to member accounts

## Related Decisions

- **ADR-001**: Monorepo supports independent module directories
- **ADR-006**: Log storage separate from collection (same pattern)
