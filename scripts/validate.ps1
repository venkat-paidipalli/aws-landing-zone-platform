#Requires -Version 5.1
<#
.SYNOPSIS
    Local validation script for the AWS Landing Zone Platform.

.DESCRIPTION
    Runs Terraform format checks, validates all test fixtures, and executes
    Terraform native tests with mocked providers for all modules.
    Designed to fail fast on the first error encountered.
    No AWS credentials required.

.EXAMPLE
    .\scripts\validate.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

# Fixtures to validate
$Fixtures = @(
    (Join-Path $RepoRoot "tests" "fixtures" "minimal"),
    (Join-Path $RepoRoot "tests" "fixtures" "organization-interface"),
    (Join-Path $RepoRoot "tests" "fixtures" "organization-invalid-inputs"),
    (Join-Path $RepoRoot "tests" "fixtures" "scp-invalid-inputs"),
    (Join-Path $RepoRoot "tests" "fixtures" "organization-with-scp"),
    (Join-Path $RepoRoot "tests" "fixtures" "config-interface"),
    (Join-Path $RepoRoot "tests" "fixtures" "config-invalid-inputs"),
    (Join-Path $RepoRoot "tests" "fixtures" "guardduty-interface"),
    (Join-Path $RepoRoot "tests" "fixtures" "guardduty-invalid-inputs"),
    (Join-Path $RepoRoot "tests" "fixtures" "security-hub-interface"),
    (Join-Path $RepoRoot "tests" "fixtures" "security-hub-invalid-inputs"),
    (Join-Path $RepoRoot "tests" "fixtures" "log-archive-interface"),
    (Join-Path $RepoRoot "tests" "fixtures" "log-archive-invalid-inputs"),
    (Join-Path $RepoRoot "tests" "fixtures" "cloudtrail-interface"),
    (Join-Path $RepoRoot "tests" "fixtures" "cloudtrail-invalid-inputs"),
    (Join-Path $RepoRoot "tests" "fixtures" "logging-foundation"),
    (Join-Path $RepoRoot "tests" "fixtures" "vpc-interface"),
    (Join-Path $RepoRoot "tests" "fixtures" "vpc-invalid-inputs"),
    (Join-Path $RepoRoot "tests" "fixtures" "vpc-ipam-interface"),
    (Join-Path $RepoRoot "tests" "fixtures" "vpc-ipam-invalid-inputs"),
    (Join-Path $RepoRoot "tests" "fixtures" "networking-foundation"),
    (Join-Path $RepoRoot "tests" "fixtures" "identity-center-interface"),
    (Join-Path $RepoRoot "tests" "fixtures" "identity-center-invalid-inputs"),
    (Join-Path $RepoRoot "environments" "reference"),
    (Join-Path $RepoRoot "environments" "reference" "control-tower")
)

# Modules with native tests
$TestModules = @(
    (Join-Path $RepoRoot "modules" "organization"),
    (Join-Path $RepoRoot "modules" "scp"),
    (Join-Path $RepoRoot "modules" "config"),
    (Join-Path $RepoRoot "modules" "guardduty"),
    (Join-Path $RepoRoot "modules" "security-hub"),
    (Join-Path $RepoRoot "modules" "log-archive"),
    (Join-Path $RepoRoot "modules" "cloudtrail"),
    (Join-Path $RepoRoot "modules" "vpc"),
    (Join-Path $RepoRoot "modules" "vpc-ipam"),
    (Join-Path $RepoRoot "modules" "identity-center"),
    (Join-Path $RepoRoot "environments" "reference"),
    (Join-Path $RepoRoot "environments" "reference" "control-tower")
)

function Write-Step {
    param([string]$Message)
    Write-Host "`n--- $Message ---" -ForegroundColor Cyan
}

function Assert-CommandExists {
    param([string]$Command)
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: '$Command' is not installed or not in PATH." -ForegroundColor Red
        exit 1
    }
}

# --------------------------------------------------
# Pre-flight check
# --------------------------------------------------
Write-Step "Checking prerequisites"
Assert-CommandExists "terraform"

$TerraformVersion = terraform version -json | ConvertFrom-Json
Write-Host "Terraform version: $($TerraformVersion.terraform_version)"

# --------------------------------------------------
# Format check (recursive from repo root)
# --------------------------------------------------
Write-Step "Terraform format check"
Push-Location $RepoRoot
try {
    terraform fmt -check -recursive
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Terraform formatting issues found. Run 'terraform fmt -recursive' to fix." -ForegroundColor Red
        exit 1
    }
    Write-Host "OK: All files formatted correctly." -ForegroundColor Green
}
finally {
    Pop-Location
}

# --------------------------------------------------
# Init and validate each fixture
# --------------------------------------------------
foreach ($FixturePath in $Fixtures) {
    $FixtureName = Split-Path -Leaf $FixturePath

    Write-Step "Terraform init ($FixtureName)"
    Push-Location $FixturePath
    try {
        terraform init -backend=false
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: terraform init failed for $FixtureName." -ForegroundColor Red
            exit 1
        }
        Write-Host "OK: Init successful." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }

    Write-Step "Terraform validate ($FixtureName)"
    Push-Location $FixturePath
    try {
        terraform validate
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: terraform validate failed for $FixtureName." -ForegroundColor Red
            exit 1
        }
        Write-Host "OK: Validation successful." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# --------------------------------------------------
# Terraform native tests (mocked provider, no AWS)
# --------------------------------------------------
foreach ($ModulePath in $TestModules) {
    $ModuleName = Split-Path -Leaf $ModulePath

    Write-Step "Terraform init ($ModuleName module for tests)"
    Push-Location $ModulePath
    try {
        terraform init -backend=false
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: terraform init failed for $ModuleName module." -ForegroundColor Red
            exit 1
        }
        Write-Host "OK: Init successful." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }

    Write-Step "Terraform test ($ModuleName module)"
    Push-Location $ModulePath
    try {
        terraform test
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ERROR: Terraform tests failed for $ModuleName module." -ForegroundColor Red
            exit 1
        }
        Write-Host "OK: All tests passed." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# --------------------------------------------------
# Summary
# --------------------------------------------------
Write-Host "`n===================================" -ForegroundColor Green
Write-Host "Core validation checks passed." -ForegroundColor Green
Write-Host "===================================`n" -ForegroundColor Green

# --------------------------------------------------
# Optional: Security scan (checkov)
# --------------------------------------------------
if (Get-Command "checkov" -ErrorAction SilentlyContinue) {
    Write-Step "Security scan (Checkov)"
    Push-Location $RepoRoot
    try {
        checkov --config-file .checkov.yml --quiet
        if ($LASTEXITCODE -ne 0) {
            Write-Host "WARNING: Checkov found issues." -ForegroundColor Yellow
        } else {
            Write-Host "OK: Security scan passed." -ForegroundColor Green
        }
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "`n--- Checkov not installed (optional) ---" -ForegroundColor DarkGray
}

# --------------------------------------------------
# Optional: Policy checks (conftest)
# --------------------------------------------------
if (Get-Command "conftest" -ErrorAction SilentlyContinue) {
    Write-Step "Policy checks (Conftest)"
    Push-Location $RepoRoot
    try {
        conftest verify --policy policies/terraform/
        if ($LASTEXITCODE -ne 0) {
            Write-Host "WARNING: Policy tests found issues." -ForegroundColor Yellow
        } else {
            Write-Host "OK: Policy checks passed." -ForegroundColor Green
        }
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "--- Conftest not installed (optional) ---" -ForegroundColor DarkGray
}

Write-Host "`n===================================" -ForegroundColor Green
Write-Host "Validation complete." -ForegroundColor Green
Write-Host "===================================`n" -ForegroundColor Green
