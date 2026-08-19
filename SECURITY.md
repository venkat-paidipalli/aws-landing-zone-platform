# Security Policy

## About This Repository

This is a **portfolio demonstration project**. It contains no real AWS
infrastructure, credentials, or production systems. All values (account IDs,
emails, ARNs) are fictional.

## Reporting Security Issues

If you discover a security issue in the Terraform module logic, configuration
patterns, or documentation that could mislead users into insecure practices:

1. **Do not open a public issue** for sensitive security concerns
2. Use [GitHub Security Advisories](https://docs.github.com/en/code-security/security-advisories) to report privately
3. Or open a regular issue for non-sensitive findings (e.g., missing best practices in module design)

## Scope

Security concerns relevant to this project include:

- Terraform configurations that could lead to insecure AWS deployments
- Accidentally committed credentials or secrets
- Misleading security documentation
- Policy/SCP logic errors that could create governance gaps

## Out of Scope

- Vulnerabilities in Terraform itself (report to HashiCorp)
- Vulnerabilities in AWS services (report to AWS)
- Issues with third-party GitHub Actions (report to their maintainers)

## Response

As a personal portfolio project, response times are best-effort.
