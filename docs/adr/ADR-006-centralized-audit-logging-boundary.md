# ADR-006: Centralized Audit Logging Boundary

## Status

Accepted

## Date

2026-08-18

## Context

A landing zone requires durable audit logging for compliance, incident
response, and forensics. Two concerns exist:

1. **Log storage** — where logs live, how they're protected, retention policy
2. **Log collection** — what events are captured, how they're delivered

These concerns have different lifecycles, security boundaries, and ownership
models. We need to decide how to structure them.

## Decision

Separate **durable log storage** from **audit event collection** into
independent modules:

```
modules/log-archive   = secure S3 bucket for log storage
modules/cloudtrail    = audit event capture and S3 delivery
```

### Composition Pattern

```
Log Archive module (storage)
    ↓ bucket_name output
CloudTrail module (collection)
    ↓ delivers events to bucket
```

The modules are not coupled internally. The composition layer wires the
log-archive bucket output into the CloudTrail bucket input.

### Security Boundary

| Concern | Module | Owner |
|---------|--------|-------|
| Log integrity | log-archive | Log Archive account |
| Log encryption | log-archive | Log Archive account |
| Log retention | log-archive | Log Archive account |
| What to capture | cloudtrail | Management account (or per-account) |
| Where to deliver | cloudtrail (input) | Composition layer |

## Consequences

### Positive

- **Independent lifecycle**: The S3 bucket persists even if CloudTrail is
  reconfigured, paused, or replaced. Logs already delivered are safe.

- **Security boundary**: The log-archive bucket is protected by its own
  policy, versioning, and encryption. CloudTrail only has write access —
  it cannot read or delete existing logs.

- **Testability**: Each module can be tested independently. The log-archive
  module validates bucket security without needing CloudTrail. The
  CloudTrail module validates trail configuration without needing S3.

- **Eventual dedicated account**: In a full landing zone, log storage lives
  in a dedicated Log Archive account. The storage module deploys there.
  CloudTrail runs in the management account (for org trails) or per-account.
  Separation makes this cross-account architecture natural.

- **Retention independence**: Log retention (lifecycle rules) is managed
  entirely by the storage module. Changing what CloudTrail captures doesn't
  affect how long logs are kept.

- **Deletion protection**: `force_destroy = false` on the bucket means
  Terraform cannot accidentally destroy logs. This protection is
  independent of the CloudTrail configuration.

- **Encryption independence**: The bucket can use KMS encryption managed by
  the Log Archive account. CloudTrail doesn't need to manage encryption —
  the bucket handles it transparently.

### Negative

- **Composition required**: The caller must wire the two modules together.
  This is one extra step vs. a monolithic logging module.

- **Bucket policy coordination**: The log-archive bucket policy must allow
  CloudTrail's service principal. This is handled by the module, but
  changes to CloudTrail's delivery behavior may require bucket policy updates.

- **No guaranteed ordering**: Terraform cannot guarantee the bucket exists
  before CloudTrail tries to deliver (in a fresh apply). The composition
  layer handles this via `depends_on` or output references.

## Alternatives Considered

### Single monolithic logging module

```hcl
module "logging" {
  # Creates bucket AND trail together
}
```

- **Pros**: One module call, no wiring needed
- **Cons**: Cannot deploy bucket to a different account than the trail,
  cannot test independently, mixed lifecycle, mixed ownership

Rejected because in a real landing zone, the bucket lives in the Log Archive
account and the trail lives in the management account.

### CloudTrail creates its own bucket

- **Pros**: Self-contained, no external dependency
- **Cons**: No central log aggregation, bucket not shared with other log
  sources (Config, ELB, VPC Flow Logs), no separation of duty

Rejected because the log-archive bucket serves multiple log sources, not
just CloudTrail.

## Future Architecture

```
Management Account
├── Organization Trail (is_organization_trail = true)
│   └── delivers to → Log Archive Account S3 bucket

Log Archive Account
├── S3 Bucket (log-archive module)
│   ├── CloudTrail logs from all accounts
│   ├── Config snapshots from all accounts
│   ├── VPC Flow Logs (future)
│   └── ELB Access Logs (future)
├── Versioning + lifecycle + encryption
└── Bucket policy: CloudTrail + Config service principals

Security Account
├── Config Aggregator (reads from all accounts)
├── GuardDuty admin (future)
└── Security Hub admin (future)
```

This architecture requires:
1. Organization trail support (future)
2. Cross-account bucket policy (future)
3. Organizations trusted access for CloudTrail (future)

The current account-level modules are building blocks for this architecture.

## Related Decisions

- **ADR-001**: Monorepo supports independent module directories
- **ADR-003**: Preventive vs detective controls (Config = detective)
- **ADR-004**: Account-level before organization-level
- **ADR-005**: Security findings aggregation boundary
