# -----------------------------------------------------------------------------
# Control Tower Boundary - Outputs
# Architecture metadata for testing and documentation.
# -----------------------------------------------------------------------------

output "governed_ous" {
  description = "Map of OUs and their governance status."
  value       = local.registered_ous
}

output "governed_ou_count" {
  description = "Number of OUs that would be governed by Control Tower."
  value       = local.governed_ou_count
}

output "ungoverned_ou_count" {
  description = "Number of OUs intentionally excluded from CT governance."
  value       = local.ungoverned_ou_count
}

output "control_categories" {
  description = "Control Tower control categories."
  value       = local.control_categories
}

output "baseline_layers" {
  description = "Ordered account baseline layers."
  value       = local.baseline_layers
}

output "terraform_owned_layers" {
  description = "Baseline layers owned by Terraform."
  value       = local.terraform_owned_layers
}

output "control_tower_owns" {
  description = "Resources owned exclusively by Control Tower."
  value       = local.control_tower_owns
}

output "terraform_owns" {
  description = "Resources owned exclusively by Terraform."
  value       = local.terraform_owns
}

output "module_compatibility" {
  description = "Compatibility assessment of each module with Control Tower."
  value       = local.module_compatibility
}

output "boundary_metadata" {
  description = "Summary of the Control Tower integration boundary."
  value = {
    governed_ous       = local.governed_ou_count
    ungoverned_ous     = local.ungoverned_ou_count
    control_categories = length(local.control_categories)
    baseline_layers    = length(local.baseline_layers)
    terraform_layers   = length(local.terraform_owned_layers)
    ct_owned_resources = length(local.control_tower_owns)
    tf_owned_resources = length(local.terraform_owns)
    modules_assessed   = length(local.module_compatibility)
    ct_deployed        = false
    aft_deployed       = false
  }
}
