output "pipeline_iam_role" {
  value       = module.pipeline_iam_role.arn
  description = "The ARN of the IAM role for the pipeline"
}

output "web_bucket_arn" {
  value       = module.web_bucket.s3_bucket_arn
  description = "The ARN of the S3 bucket for the web"
}

################################################################################
# Contact Form Outputs
################################################################################
output "api_gateway_url" {
  description = "API Gateway URL for contact form"
  value       = "${module.api_gateway_contact_form.stage_invoke_url}/contact"
}

output "api_gateway_custom_domain_url" {
  description = "API Gateway custom domain URL"
  value       = "https://${var.api_gateway_domain_name}/contact"
}

output "lambda_function_name" {
  description = "Lambda function name for contact form"
  value       = module.web_contact_form_lambda.lambda_function_name
}

output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.ses_domain.arn
}

output "ses_domain_identity_verification_token" {
  description = "Verification token for the SES domain identity"
  value       = aws_ses_domain_identity.ses_domain.verification_token
  sensitive   = true
}

output "ses_dkim_tokens" {
  description = "DKIM tokens for the SES domain"
  value       = aws_ses_domain_dkim.ses_domain_dkim.dkim_tokens
  sensitive   = true
}
