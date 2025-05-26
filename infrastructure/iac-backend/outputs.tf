output "s3_bucket_id" {
  value       = module.state_bucket.s3_bucket_id
  description = "The ID of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = module.state_bucket.s3_bucket_arn
  description = "The ARN of the S3 bucket"
}
