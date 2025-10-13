################################################################################
# S3 bucket for lambdas
################################################################################
module "lambdas_artifacts_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket_prefix = "web-lambdas-artifacts-"

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  object_lock_enabled       = true
  object_lock_configuration = {}

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

  lifecycle_rule = [
    {
      id      = "expiration"
      enabled = true
      filter  = {}

      noncurrent_version_expiration = {
        newer_noncurrent_versions = 10
        days                      = 180
      }
    },
  ]
}

################################################################################
# Lambda function for web contact form
################################################################################
module "web_contact_form_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.9.0"
  create  = true

  function_name = "web-contact-form"
  description   = "Lambda function for web contact form"
  handler       = "contact-form.lambda_handler"
  runtime       = "python3.12"
  publish       = true
  timeout       = 60

  replace_security_groups_on_destroy = true # ease deletion of security groups

  # Package
  source_path = [
    {
      path             = "${path.module}/lambdas/web-contact-form"
      pip_requirements = false  # Disable pip since boto3 is in Lambda runtime
    }
  ]
  store_on_s3 = true
  s3_bucket   = module.lambdas_artifacts_bucket.s3_bucket_id
  s3_prefix   = "lambda-builds/web-contact-form"

  # Tags
  tags = {
    Name = "web-contact-form"
  }

  # Environment
  environment_variables = {
    CONTACT_EMAIL         = var.web_contact_form_email
    FORWARD_EMAIL         = var.web_contact_form_forward_email
    RECAPTCHA_SECRET_KEY  = var.recaptcha_secret_key
  }

  # Logs
  cloudwatch_logs_log_group_class   = "STANDARD"
  cloudwatch_logs_retention_in_days = 7

  # IAM Role
  attach_policy_statements = true
  policy_statements = {
    sesPolicy = {
      effect = "Allow"
      actions = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      resources = ["*"]
    }
  }

  attach_policies = true
  policies = [
    "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
  number_of_policies = 3

  # Lambda permissions for API Gateway
  allowed_triggers = {
    APIGatewayV2 = {
      service    = "apigateway"
      source_arn = "${module.api_gateway_contact_form.api_execution_arn}/*/*"
    }
  }

  # Networking
#   vpc_subnet_ids         = []
#   vpc_security_group_ids = []

  timeouts = {
    create = "10m"
    update = "5m"
    delete = "5m"
  }
}

################################################################################
# API Gateway v2 (HTTP API) for contact form
################################################################################
module "api_gateway_contact_form" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "5.3.1"

  name          = "web-contact-api"
  description   = "HTTP API Gateway for web contact form"
  protocol_type = "HTTP"

  # Domain configuration
  hosted_zone_name      = var.web_domain
  domain_name           = var.api_gateway_domain_name
  create_domain_records = true
  create_certificate    = true

  # CORS configuration
  cors_configuration = {
    allow_headers = [
      "content-type",
      "x-amz-date",
      "authorization",
      "x-api-key",
      "x-amz-security-token"
    ]
    allow_methods = ["GET", "OPTIONS", "POST"]
    allow_origins = ["*"]
  }

  # Routes and integrations
  routes = {
    "POST /contact" = {
      integration = {
        uri                    = module.web_contact_form_lambda.lambda_function_arn
        type                   = "AWS_PROXY"
        payload_format_version = "2.0"
      }
    }
  }

  # Stage configuration
  stage_name        = "prod"
  stage_description = "Production stage for contact form API"

  # Access logs
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = 7
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  # Tags
  tags = {
    Name = "web-contact-api"
  }
}

################################################################################
# SES domain verification
################################################################################
resource "aws_ses_domain_identity" "ses_domain" {
  domain = var.web_domain
}

resource "aws_route53_record" "amazonses_verification_record" {
  zone_id = data.aws_route53_zone.web_domain.zone_id
  name    = "_amazonses.${var.web_domain}"
  type    = "TXT"
  ttl     = "1800"
  records = [aws_ses_domain_identity.ses_domain.verification_token]
}

resource "aws_ses_domain_dkim" "ses_domain_dkim" {
  domain = aws_ses_domain_identity.ses_domain.domain
}

resource "aws_route53_record" "amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.web_domain.zone_id
  name    = "${element(aws_ses_domain_dkim.ses_domain_dkim.dkim_tokens, count.index)}._domainkey.${var.web_domain}"
  type    = "CNAME"
  ttl     = "1800"
  records = ["${element(aws_ses_domain_dkim.ses_domain_dkim.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_route53_record" "amazonses_spf_record" {
  zone_id = data.aws_route53_zone.web_domain.zone_id
  name    = aws_ses_domain_identity.ses_domain.domain
  type    = "TXT"
  ttl     = "3600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_ses_domain_mail_from" "custom_mail_from" {
  domain                 = aws_ses_domain_identity.ses_domain.domain
  mail_from_domain       = "contact.${var.web_domain}"
  behavior_on_mx_failure = "UseDefaultValue"
}

resource "aws_route53_record" "custom_mail_from_mx" {
  zone_id = data.aws_route53_zone.web_domain.zone_id
  name    = aws_ses_domain_mail_from.custom_mail_from.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}
