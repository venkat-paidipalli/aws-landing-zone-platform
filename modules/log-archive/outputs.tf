# -----------------------------------------------------------------------------
# Log Archive Module - Outputs
# -----------------------------------------------------------------------------

output "bucket_id" {
  description = "The ID of the log archive S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the log archive S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_name" {
  description = "The name of the log archive S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "encryption_type" {
  description = "The encryption algorithm used for the bucket."
  value       = var.encryption_type
}

output "versioning_enabled" {
  description = "Whether versioning is enabled on the bucket."
  value       = var.enable_versioning
}

output "log_archive_metadata" {
  description = "Summary metadata about the log archive configuration."
  value = {
    bucket_name           = var.bucket_name
    encryption_type       = var.encryption_type
    versioning_enabled    = var.enable_versioning
    force_destroy         = var.force_destroy
    transition_to_ia_days = var.transition_to_ia_days
    transition_to_glacier = var.transition_to_glacier_days
    expiration_days       = var.expiration_days
  }
}
