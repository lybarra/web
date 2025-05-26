variable "project_name" {
  description = "The name of the project. All resources will be prefixed with this name"
  type        = string
  default     = "web"
}

variable "project_profile" {
  description = "The AWS profile to use"
  type        = string
}

variable "project_region" {
  description = "The AWS region to use"
  type        = string
  default     = "us-east-1"
}
