# ADR-008: Identity and Access Boundary

## Status

Accepted

## Date

2026-08-18

## Context

IAM Identity Center manages two concerns:

1. **Identity source** — where users/groups come from (Identity Store, Entra
   ID, Okta, etc.) and how they're provisioned (manual, SCIM)
2. **Authorization** — what permission sets exist and which principals get
   assigned to which accounts

These have different lifecycles, ownership, and operational characteristics.

## Decision

Keep **identity source/federation** separate from **permission-set
provisioning and account assignment**.

### Module Boundary

| Concern | Module | Responsibility |
|---------|--------|----------------|
| Permission sets + assignments | `modules/identity-center` | What access exists, who gets it where |
| User/group creation | Not implemented (future) | Identity lifecycle |
| External IdP (SAML/OIDC) | Not implemented (future) | Federation |
| SCIM provisioning | Not implemented (future) | Automated sync |

### Design Principles

1. **Callers provide principal IDs** — the module does not create users or
   groups. It receives UUID principal IDs from the caller.

2. **Group-based assignments** — assignments should reference groups, not
   individual users. Group membership is managed separately.

3. **Least privilege** — permission sets grant the minimum access needed.
   Broad access (AdministratorAccess) is augmented with inline deny
   policies for dangerous actions.

4. **Explicit assignments** — no wildcard "everyone gets access everywhere."
   Each assignment is declared explicitly.

## Consequences

### Positive

- **Testability**: Permission sets can be tested without real users/groups.
  Synthetic UUID principal IDs work for validation.

- **Separation of identity lifecycle**: Adding/removing users doesn't require
  changing Terraform permission-set code. Group membership is managed
  in the identity store.

- **Federation flexibility**: The permission-set module works regardless of
  whether the identity source is the built-in store, Entra ID, or Okta.

- **Auditability**: Permission assignments are explicit in code —
  reviewable in PRs.

### Negative

- **Synthetic principals in testing**: Cannot verify principal existence at
  plan time without the identity store.

- **Manual coordination**: Someone must provide principal IDs to the
  Terraform configuration.

- **No user visibility**: This module cannot answer "who is in this group?"

## Alternatives Considered

### Combined identity + authorization module

Rejected — mixing user lifecycle with permission management creates a
monolithic module with mixed ownership.

### Data source lookup for principals

Rejected for v1 — requires live Identity Store API access at plan time,
breaks mocked testing.

## Future Integration

1. **External IdP** (Entra/Okta) provisions users+groups via SCIM
2. **Identity Store** module (future) manages groups for non-federated users
3. **This module** receives group IDs and creates permission sets + assignments
4. **Control Tower** may manage some baseline permission sets automatically

## Related Decisions

- **ADR-004**: Account-level before organization-level
- **ADR-005**: Security findings aggregation boundary
