#######################################################
# Cloudfront distribution
#######################################################
module "web_cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.1"

  aliases = var.cloudfront_aliases

  comment             = "${var.project_environment}-${var.project_name}-web"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = true

  # monitoring
  create_monitoring_subscription = true

  # waf
  # web_acl_id = aws_wafv2_web_acl.cloudfront.arn

  create_origin_access_control = true
  origin_access_control = {
    "${var.project_environment}_s3_web" = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  # logging_config = {
  #   bucket = "logs-my-cdn.s3.amazonaws.com"
  # }
  default_root_object = "index.html"
  origin = {
    web = {
      domain_name           = module.web_bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control = "${var.project_environment}_s3_web"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "web"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # query_string    = false
    # compress        = false
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c" #https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html#managed-response-headers-policies-cors

    # query_string_cache_keys = []
    # headers                 = ["*"]
    # cookies_forward = "none"
  }

  viewer_certificate = {
    acm_certificate_arn            = module.web_certificate.acm_certificate_arn
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

#######################################################
# S3 bucket
#######################################################
module "web_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = var.web_domain

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  attach_policy = true
  policy        = data.aws_iam_policy_document.web_s3_policy.json

  attach_deny_insecure_transport_policy = false
  attach_require_latest_tls_policy      = false

  object_lock_enabled = true
  object_lock_configuration = {
    object_lock_enabled = "Enabled"
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 7
      }
    }
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    enabled = true
  }

  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT"]
      allowed_origins = ["*"]
      expose_headers  = ["Access-Control-Allow-Origin"]
    },
    {
      allowed_methods = ["PUT"]
      allowed_origins = ["https://www.${var.web_domain}"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
  website = {
    # conflicts with "error_document"
    #        redirect_all_requests_to = {
    #          host_name = "https://modules.tf"
    #        }

    index_document = "index.html"
    error_document = "error.html"
    /*routing_rules = [{
      condition = {
        key_prefix_equals = "docs/"
      },
      redirect = {
        replace_key_prefix_with = "documents/"
      }
      }, {
      condition = {
        http_error_code_returned_equals = 404
        key_prefix_equals               = "archive/"
      },
      redirect = {
        host_name          = "archive.myhost.com"
        http_redirect_code = 301
        protocol           = "https"
        replace_key_with   = "not_found.html"
      }
    }]*/
  }
}

data "aws_iam_policy_document" "web_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.web_bucket.s3_bucket_arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.web_cloudfront.cloudfront_distribution_arn]
    }
  }
}
