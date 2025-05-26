output "pipeline_iam_role" {
  value       = module.pipeline_iam_role.arn
  description = "The ARN of the IAM role for the pipeline"
}

output "web_bucket_arn" {
  value       = module.web_bucket.s3_bucket_arn
  description = "The ARN of the S3 bucket for the web"
}
