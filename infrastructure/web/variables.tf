variable "api_gateway_domain_name" {
  description = "The domain name for the API Gateway"
  type        = string
  default     = "example.com"
}

variable "web_contact_form_email" {
  description = "The primary email address for the web contact form"
  type        = string
  default     = "info@example.com"
}

variable "web_contact_form_forward_email" {
  description = "Additional email address to forward contact form messages (optional)"
  type        = string
  default     = ""
}

variable "recaptcha_secret_key" {
  description = "Google reCAPTCHA v3 secret key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "linkedin_url" {
  description = "LinkedIn profile URL"
  type        = string
  default     = "https://www.linkedin.com/in/yourprofile/"
}

variable "github_url" {
  description = "GitHub profile URL"
  type        = string
  default     = "https://github.com/yourusername"
}

variable "owner_name" {
  description = "Name of the website owner"
  type        = string
  default     = "Your Name"
}

variable "owner_title" {
  description = "Professional title of the website owner"
  type        = string
  default     = "DevOps Engineer"
}

variable "cloudfront_aliases" {
  description = "The aliases for the cloudfront distribution"
  type        = list(string)
  default     = ["example.com", "*.example.com"]
}

variable "oidc_subjects" {
  description = "The subjects for the oidc provider"
  type        = list(string)
  default     = ["github_org/repository:*"]
}

variable "project_name" {
  description = "The name of the project. All resources will be prefixed with this name"
  type        = string
}

variable "project_environment" {
  description = "The environment of the project. Used for tagging and naming. Typically 'dev', 'test', or 'prod'"
  type        = string
}

variable "project_profile" {
  description = "The AWS profile to use"
  type        = string
}

variable "project_region" {
  description = "The AWS region to use"
  type        = string
}

variable "web_domain" {
  description = "The domain of the web application"
  type        = string
  default     = "example.com"
}

################################################################################
# API Gateway Security Variables
################################################################################
variable "api_throttle_burst_limit" {
  description = "Maximum concurrent requests allowed for API Gateway"
  type        = number
  default     = 10
}

variable "api_throttle_rate_limit" {
  description = "Maximum requests per second allowed for API Gateway"
  type        = number
  default     = 5
}

################################################################################
# Lambda Security Variables
################################################################################
variable "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions for Lambda to prevent runaway costs"
  type        = number
  default     = 5
}

################################################################################
# WAF Security Variables
################################################################################
variable "enable_waf" {
  description = "Enable AWS WAF protection for the API Gateway (additional cost ~$11/month)"
  type        = bool
  default     = false
}

variable "waf_rate_limit_general" {
  description = "Maximum requests per IP in 5 minutes (general)"
  type        = number
  default     = 100
}

variable "waf_rate_limit_post" {
  description = "Maximum POST requests per IP in 5 minutes"
  type        = number
  default     = 10
}

variable "waf_enable_geo_blocking" {
  description = "Enable geographic blocking in WAF"
  type        = bool
  default     = false
}

variable "waf_allowed_countries" {
  description = "List of country codes allowed when geo-blocking is enabled"
  type        = list(string)
  default     = ["US", "CA", "GB", "AR", "MX", "ES"]
}
