# -----------------------------------------------------------------------------
# Reference Environment - Variables
#
# Minimal variable surface. Most configuration is defined in locals.tf
# for this reference composition. Real environments would externalize
# more values via tfvars.
# -----------------------------------------------------------------------------

variable "approved_regions" {
  description = "AWS regions approved for use in this landing zone."
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

variable "environment_name" {
  description = "Name of this environment composition."
  type        = string
  default     = "reference"
}
