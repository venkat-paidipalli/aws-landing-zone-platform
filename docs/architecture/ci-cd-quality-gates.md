# CI/CD Quality Gates

## Overview

Every infrastructure change must pass automated validation before merge.
This pipeline is **credential-free** — it validates structure, behavior,
security, and policy without deploying to AWS.

## Pipeline Flow

```
Developer Change
        ↓
Pull Request
        ↓
┌─────────────────────────────────────────────────────────┐
│ CI Quality Gates                                        │
│                                                         │
│  ┌──────────────┐   ┌─────────────────┐               │
│  │ Format Check │──▶│ Validate         │               │
│  │ (terraform   │   │ (init + validate │               │
│  │  fmt -check) │   │  all configs)    │               │
│  └──────────────┘   └───────┬─────────┘               │
│                              │                          │
│                              ▼                          │
│                     ┌─────────────────┐                │
│                     │ Terraform Tests  │                │
│                     │ (155+ mocked)    │                │
│                     └───────┬─────────┘                │
│                              │                          │
│  ┌──────────────┐            │    ┌─────────────────┐  │
│  │ Secret Scan  │            │    │ Security Scan   │  │
│  │ (gitleaks)   │            │    │ (Checkov)       │  │
│  └──────┬───────┘            │    └───────┬─────────┘  │
│         │                    │            │            │
│         ▼                    ▼            ▼            │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Quality Gate (all must pass)        │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
        ↓
Merge Eligible
```

## Gate Details

| Gate | Tool | Failure Behavior | Credential-Free |
|------|------|-----------------|-----------------|
| Format | `terraform fmt -check -recursive` | Block merge | Yes |
| Validate | `terraform init -backend=false` + `validate` | Block merge | Yes |
| Test | `terraform test` (mock_provider) | Block merge | Yes |
| Security | Checkov | Block merge | Yes |
| Secrets | gitleaks | Block merge | Yes |
| Policy | conftest (OPA/Rego) | Block merge | Yes |

## No Deployment Stage

This portfolio deliberately stops at validation. There is no:
- `terraform plan` against real infrastructure
- `terraform apply`
- `terraform destroy`
- AWS credential configuration
- OIDC / AssumeRole
- Environment promotion

Deployment would be a future extension requiring real AWS accounts.

## GitHub Actions Configuration

- **Trigger**: PR to main, push to main
- **Concurrency**: One run per ref, cancel stale runs
- **Permissions**: `contents: read` only
- **Terraform version**: Read from `.terraform-version`
- **Actions used**: hashicorp/setup-terraform@v3, bridgecrewio/checkov-action@v12, gitleaks/gitleaks-action@v2

## Local Validation

Developers can run the same quality gates locally:

```bash
# Full gate (Linux/macOS)
make check

# Full gate (Windows)
.\scripts\validate.ps1
```

Optional tools (run when installed):
- `checkov` — security scanning
- `conftest` — policy checks
- `gitleaks` — secret scanning

## Lock File Strategy

- `.terraform.lock.hcl` files: NOT committed for reusable modules
- Environments generate lock files during `init`
- CI runs `init -backend=false` fresh each time (no cached lock)
- `.gitignore` excludes `.terraform/` directories

## Supply Chain

| Action | Maintainer | Purpose |
|--------|-----------|---------|
| `actions/checkout@v4` | GitHub | Repository checkout |
| `hashicorp/setup-terraform@v3` | HashiCorp | Terraform CLI |
| `bridgecrewio/checkov-action@v12` | Prisma Cloud | Security scanning |
| `gitleaks/gitleaks-action@v2` | gitleaks | Secret scanning |

All are established, actively maintained actions from known vendors.
