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
