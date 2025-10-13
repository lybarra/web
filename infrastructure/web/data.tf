data "aws_route53_zone" "web_domain" {
  name         = var.web_domain
  private_zone = false
}

data "aws_region" "current" {}
