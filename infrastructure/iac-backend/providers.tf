terraform {
  required_version = ">= 0.13.1"
  backend "s3" { # comment this block on bootstrap
    bucket  = "lybarra-web-terraform-states-20250525132001152600000001"
    key     = "iac-backend/terraform.tfstate"
    region  = "us-east-1"
    profile = "lybarra-main"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.98.0"
    }
  }
}

provider "aws" {
  region  = var.project_region
  profile = var.project_profile
  default_tags {
    tags = {
      Terraform        = "yes"
      Terraform-folder = basename(path.cwd)
      Project          = var.project_name
    }
  }
}
