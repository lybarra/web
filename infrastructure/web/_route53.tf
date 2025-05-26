
module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "5.0.0"

  zones = {
    (var.web_domain) = {
      comment = "Main domain"
      tags = {
        environment = "production"
      }
    }
  }

  tags = {}
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "5.0.0"

  zone_name = module.zones.route53_zone_name[var.web_domain]

  records = [
    {
      name = ""
      type = "A"
      # records = [var.web_domain]
      alias = {
        name    = module.web_cloudfront.cloudfront_distribution_domain_name
        zone_id = module.web_cloudfront.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name = "*"
      type = "A"
      alias = {
        name    = module.web_cloudfront.cloudfront_distribution_domain_name
        zone_id = module.web_cloudfront.cloudfront_distribution_hosted_zone_id
      }
    },
  ]
}
