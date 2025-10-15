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

################################################################################
# Security Outputs
################################################################################
output "waf_enabled" {
  description = "Whether WAF protection is enabled"
  value       = var.enable_waf
}

output "api_gateway_waf_web_acl_id" {
  description = "The ID of the WAF WebACL protecting the API Gateway (null if WAF disabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.contact_form_api_waf[0].id : null
}

output "api_gateway_waf_web_acl_arn" {
  description = "The ARN of the WAF WebACL protecting the API Gateway (null if WAF disabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.contact_form_api_waf[0].arn : null
}

output "waf_cloudwatch_log_group" {
  description = "CloudWatch log group for WAF logs (null if WAF disabled)"
  value       = var.enable_waf ? aws_cloudwatch_log_group.waf_log_group[0].name : null
}

output "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions for Lambda"
  value       = var.lambda_reserved_concurrency
}

output "api_throttle_settings" {
  description = "API Gateway throttle settings"
  value = {
    burst_limit = var.api_throttle_burst_limit
    rate_limit  = var.api_throttle_rate_limit
  }
}

output "waf_rate_limits" {
  description = "WAF rate limiting configuration"
  value = {
    general_limit = var.waf_rate_limit_general
    post_limit    = var.waf_rate_limit_post
  }
}
