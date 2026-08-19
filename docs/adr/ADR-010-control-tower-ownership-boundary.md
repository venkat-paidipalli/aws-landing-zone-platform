# ADR-010: Control Tower Ownership Boundary

## Status

Accepted

## Date

2026-08-18

## Context

AWS Control Tower provides a managed landing zone governance framework. It
creates and manages organizational resources (CloudTrail, Config, SCPs, IAM
roles) that overlap with some Terraform modules in this repository.

We need to define clear ownership boundaries so that Terraform and Control
Tower can coexist without drift, conflicts, or duplicate enforcement.

## Decision

**Control Tower and Terraform use explicit resource ownership boundaries.
Terraform must complement Control Tower rather than recreate or fight
Control Tower-managed resources.**

### Ownership Model

| Owner | Resources |
|-------|-----------|
| Control Tower | Organization trail, baseline Config recorder, mandatory SCPs, landing zone IAM roles, CT log archive bucket, account enrollment |
| Terraform | Custom SCPs, custom Config rules, GuardDuty detector, Security Hub standards, platform log archive, VPC/IPAM, permission sets, account-level trails |

### Integration Rules

1. Terraform must never manage a resource that Control Tower creates
2. Custom Terraform resources must be namespaced to avoid collision
3. CT self-healing and repair operations take precedence over Terraform state
4. Module compatibility is assessed before CT deployment
5. The organization module switches to "consumption mode" in CT environments

## Consequences

### Positive

- **No drift conflicts**: Clear boundaries mean CT and Terraform never
  compete for the same resource.

- **CT upgrades are safe**: Because Terraform doesn't manage CT resources,
  CT landing zone upgrades proceed without Terraform interference.

- **Additive value**: Terraform adds controls and services beyond the CT
  baseline rather than duplicating it.

- **Testable independently**: The boundary model itself is tested via
  Terraform metadata tests (20 assertions verify the architecture).

### Negative

- **Organization module needs adjustment**: In CT environments, the module
  cannot create OUs/org — it must consume existing ones.

- **CloudTrail module becomes optional**: CT's org trail replaces the need
  for account-level trails in most cases.

- **Audit overhead**: Platform team must verify that custom Terraform SCPs
  don't conflict with CT-managed policies before deployment.

## Alternatives Considered

### Terraform manages everything (no CT)

- **Pros**: Single tool, no ownership confusion
- **Cons**: Loses CT governance framework, guardrail catalog, drift
  detection, account factory automation

Rejected — CT provides substantial governance value that would be expensive
to rebuild in Terraform.

### Control Tower manages everything (no custom Terraform)

- **Pros**: Single governance source, no boundary management
- **Cons**: CT cannot manage networking, custom security rules, platform-
  specific permission sets, or IPAM. Many organizations need beyond-CT
  customization.

Rejected — real platforms need customization beyond CT's catalog.

### Shared management (both manage same resources)

- **Pros**: Flexibility
- **Cons**: Guaranteed drift, repair conflicts, failed upgrades, debugging
  nightmares

Rejected — shared ownership of the same resource is an anti-pattern.

## Related Decisions

- **ADR-003**: Preventive vs detective controls
- **ADR-004**: Account-level before organization-level
- **ADR-009**: Environment composition boundary
