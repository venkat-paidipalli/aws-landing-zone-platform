# Contributing

Thank you for your interest in this project.

## Development Workflow

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7
- Git

### Optional Tools

- [Checkov](https://www.checkov.io/) — security scanning
- [Conftest](https://www.conftest.dev/) — policy checks
- [gitleaks](https://github.com/gitleaks/gitleaks) — secret scanning

### Making Changes

1. Create a feature branch from `main`
2. Make your changes
3. Run the quality gate locally:

```bash
# Format
terraform fmt -recursive

# Validate + test (required)
make check

# Full gate including security tools (when installed)
make check-all
```

4. Ensure all checks pass before opening a PR

### Quality Gates

Every pull request must pass:

| Gate | Command | Required |
|------|---------|:--------:|
| Format | `terraform fmt -check -recursive` | Yes |
| Validate | `make validate` | Yes |
| Test | `make test` | Yes |
| Security | `make security` | When available |
| Policy | `make policy` | When available |
| Secrets | `make secrets` | When available |

### Code Standards

- All Terraform files must pass `terraform fmt`
- All modules must have tests using `mock_provider`
- All modules must have a README.md
- No real AWS credentials, account IDs, or emails
- Use `@example.invalid` for fictional email addresses
- Use clearly synthetic values for account IDs and ARNs
- No `aws:` prefix in tags
- Document architectural decisions in `docs/adr/`

### Pull Request Expectations

- Clear description of what and why
- Tests for new module functionality
- Documentation updated if interfaces change
- No deployment — this repository validates locally only
