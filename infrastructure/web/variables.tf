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
