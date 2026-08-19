# AWS Landing Zone Platform - Developer Makefile
#
# Provides convenience targets for local development on systems with make.
# Windows users: use scripts/validate.ps1 instead (make is not required).
#
# No AWS credentials required for any target.

.PHONY: fmt fmt-check validate test check clean

MODULE_ORG := modules/organization
MODULE_SCP := modules/scp
MODULE_CONFIG := modules/config
MODULE_GD := modules/guardduty
MODULE_SH := modules/security-hub
MODULE_LA := modules/log-archive
MODULE_CT := modules/cloudtrail
MODULE_VPC := modules/vpc
MODULE_IPAM := modules/vpc-ipam
MODULE_IDC := modules/identity-center
ENV_REF := environments/reference
ENV_CT := environments/reference/control-tower

FIXTURES := tests/fixtures/minimal \
	tests/fixtures/organization-interface \
	tests/fixtures/organization-invalid-inputs \
	tests/fixtures/scp-invalid-inputs \
	tests/fixtures/organization-with-scp \
	tests/fixtures/config-interface \
	tests/fixtures/config-invalid-inputs \
	tests/fixtures/guardduty-interface \
	tests/fixtures/guardduty-invalid-inputs \
	tests/fixtures/security-hub-interface \
	tests/fixtures/security-hub-invalid-inputs \
	tests/fixtures/log-archive-interface \
	tests/fixtures/log-archive-invalid-inputs \
	tests/fixtures/cloudtrail-interface \
	tests/fixtures/cloudtrail-invalid-inputs \
	tests/fixtures/logging-foundation \
	tests/fixtures/vpc-interface \
	tests/fixtures/vpc-invalid-inputs \
	tests/fixtures/vpc-ipam-interface \
	tests/fixtures/vpc-ipam-invalid-inputs \
	tests/fixtures/networking-foundation \
	tests/fixtures/identity-center-interface \
	tests/fixtures/identity-center-invalid-inputs \
	$(ENV_REF) \
	$(ENV_CT)

MODULES := $(MODULE_ORG) $(MODULE_SCP) $(MODULE_CONFIG) $(MODULE_GD) $(MODULE_SH) $(MODULE_LA) $(MODULE_CT) $(MODULE_VPC) $(MODULE_IPAM) $(MODULE_IDC) $(ENV_REF) $(ENV_CT)

# Format all Terraform files in-place
fmt:
	terraform fmt -recursive

# Check formatting without modifying files (CI-friendly)
fmt-check:
	terraform fmt -check -recursive

# Structural validation: init + validate all fixtures
validate: fmt-check
	@for fixture in $(FIXTURES); do \
		terraform -chdir=$$fixture init -backend=false && \
		terraform -chdir=$$fixture validate || exit 1; \
	done

# Run Terraform native tests with mocked provider (no AWS credentials)
test:
	@for mod in $(MODULES); do \
		terraform -chdir=$$mod init -backend=false && \
		terraform -chdir=$$mod test || exit 1; \
	done

# Full quality gate: format + validate + test
check: validate test

# Security scan (requires checkov installed)
security:
	@command -v checkov >/dev/null 2>&1 || { echo "checkov not installed — skipping"; exit 0; }
	checkov --config-file .checkov.yml --quiet

# Policy checks (requires conftest installed)
policy:
	@command -v conftest >/dev/null 2>&1 || { echo "conftest not installed — skipping"; exit 0; }
	conftest verify --policy policies/terraform/

# Secret scan (requires gitleaks installed)
secrets:
	@command -v gitleaks >/dev/null 2>&1 || { echo "gitleaks not installed — skipping"; exit 0; }
	gitleaks detect --source . --config .gitleaks.toml --no-git

# Complete quality gate (all tools)
check-all: check security policy secrets

# Remove local Terraform working directories
clean:
	@for dir in $(FIXTURES) $(MODULES); do \
		rm -rf $$dir/.terraform; \
		rm -f $$dir/.terraform.lock.hcl; \
	done
