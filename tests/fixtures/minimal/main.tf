# Minimal Terraform validation fixture.
#
# Purpose: Verify that the local Terraform toolchain is functional.
# This fixture contains no AWS resources and requires no credentials.

terraform {
  required_version = "~> 1.7"
}

# terraform_data is a provider-independent managed resource available
# in Terraform 1.4+. It serves as a lightweight sanity check that
# plan/apply mechanics work without external dependencies.

resource "terraform_data" "sanity_check" {
  input = "landing-zone-platform-toolchain-ok"
}

output "status" {
  description = "Confirms the Terraform toolchain is operational."
  value       = terraform_data.sanity_check.output
}
