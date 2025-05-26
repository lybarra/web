module "web_certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name = var.web_domain
  zone_id     = module.zones.route53_zone_zone_id[var.web_domain]

  key_algorithm     = "EC_prime256v1"
  validation_method = "DNS"

  subject_alternative_names = [
    var.web_domain,
    "*.${var.web_domain}"
  ]

  wait_for_validation = false

  tags = {
    Name = var.web_domain
  }
}
