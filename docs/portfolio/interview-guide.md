# Interview Guide

## 30-Second Explanation

"I built a production-style AWS landing zone platform from scratch using
Terraform. It demonstrates multi-account governance with Organizations, SCPs,
security services, centralized logging, networking, and identity management —
all validated by 155 mocked tests without requiring AWS credentials."

## 2-Minute Architecture Explanation

"The platform has 10 independently testable Terraform modules covering the
full landing zone stack:

**Organization layer** — AWS Organizations with 7 OUs and 8 fictional member
accounts, plus Service Control Policies for preventive guardrails.

**Security layer** — AWS Config for detective governance, GuardDuty for threat
detection, Security Hub for compliance aggregation. All account-level with
documented paths to organization-wide administration.

**Logging layer** — Secure S3 log archive with versioning, encryption, and
lifecycle rules, plus CloudTrail for management event capture.

**Networking layer** — VPC IPAM for centralized address management and
configurable VPCs with private/data subnet segmentation.

**Identity layer** — IAM Identity Center permission sets with group-based
account assignments following least privilege.

These compose into a reference environment that demonstrates real module
wiring — organization outputs feed SCP targeting, account IDs feed identity
assignments, log archive bucket names feed CloudTrail delivery.

The CI pipeline validates everything without AWS credentials using Terraform
native tests with mocked providers, Checkov for security scanning, gitleaks
for secret detection, and OPA/Rego for governance policy enforcement."

## Key Design Decisions

1. **Modules are independent** — each testable alone, no circular dependencies
2. **Environments own composition** — wiring lives in the environment layer, not modules
3. **Account-level before org-level** — reduces blast radius, enables incremental rollout
4. **Control Tower documented, not deployed** — shows CT knowledge without requiring real accounts
5. **Conservative defaults** — no public subnets, no IGW, no NAT, no org trails by default
6. **Credential-free validation** — entire CI pipeline works without AWS access

## Why Control Tower Isn't Deployed

"This is a portfolio project. Deploying Control Tower requires a real AWS
Organization with real accounts and real billing. Instead, I documented
the integration boundary — which resources CT owns versus Terraform, how
the modules would coexist, and where ownership conflicts could arise. The
architecture is CT-ready but doesn't require CT to validate."

## Why Ownership Separation Matters

"In production, Control Tower and Terraform fighting over the same resources
causes drift, failed upgrades, and governance gaps. By defining explicit
ownership boundaries upfront — CT owns the org trail, Terraform owns custom
SCPs — you prevent the most common landing zone maintenance problems."

## Testing Strategy

"155 Terraform native tests using `mock_provider` validate resource creation,
configuration correctness, and architecture invariants without AWS API calls.
Tests are split into module-level (124 tests) and composition-level (31 tests).
Invalid-input fixtures verify that validation rules reject bad configuration."

## Security Strategy

"Defense in depth with three layers:
- **Preventive** (SCPs) — blocks dangerous actions before they happen
- **Detective** (Config, GuardDuty, SecurityHub) — identifies non-compliance after the fact
- **Audit** (CloudTrail, log archive) — provides forensic evidence

Plus CI-time security scanning (Checkov) and secret detection (gitleaks)."

## CI Strategy

"Six gates, all credential-free: format, validate, test, security scan, secret
scan, policy check. GitHub Actions runs on PR and push to main. No deployment
stage exists — this deliberately stops at validation."

## Major Tradeoffs

- **No real deployment** — validates architecture but can't prove runtime behavior
- **Account-level only** — no org-wide security admin yet (documented as future)
- **Static CIDRs** — IPAM documents the plan but doesn't dynamically allocate
- **No Transit Gateway** — VPCs are isolated until TGW module is added

## Future Production Extensions

If this were taken to production:
1. Deploy Control Tower and register OUs
2. Add Transit Gateway for cross-VPC connectivity
3. Enable org-level GuardDuty/SecurityHub delegated admin
4. Configure organization CloudTrail
5. Add deployment pipeline with plan → approve → apply workflow
6. Implement AFT for account vending
7. Add Route 53 Resolver for centralized DNS
