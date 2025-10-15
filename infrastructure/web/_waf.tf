################################################################################
# CloudWatch Log Group for WAF logs
################################################################################
resource "aws_cloudwatch_log_group" "waf_log_group" {
  count = var.enable_waf ? 1 : 0

  name              = "/aws/wafv2/contact-form-api"
  retention_in_days = 7

  tags = {
    Name = "waf-contact-form-api-logs"
  }
}

################################################################################
# WAF WebACL for API Gateway Protection
################################################################################
resource "aws_wafv2_web_acl" "contact_form_api_waf" {
  count = var.enable_waf ? 1 : 0

  name        = "contact-form-api-waf"
  description = "WAF rules for contact form API protection against abuse and DDoS"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 1: Rate-based rule to prevent email flooding
  # Blocks IPs that make more than configured requests in 5 minutes
  rule {
    name     = "rate-limit-rule"
    priority = 1

    action {
      block {
        custom_response {
          response_code = 429
          custom_response_body_key = "rate_limit_response"
        }
      }
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit_general
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Stricter rate limit for POST requests (contact form submissions)
  # Blocks IPs that make more than configured POST requests in 5 minutes
  rule {
    name     = "post-rate-limit-rule"
    priority = 2

    action {
      block {
        custom_response {
          response_code = 429
          custom_response_body_key = "rate_limit_response"
        }
      }
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit_post
        aggregate_key_type = "IP"

        scope_down_statement {
          byte_match_statement {
            search_string = "POST"
            field_to_match {
              method {}
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PostRateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: AWS Managed Rules - Core Rule Set (CRS)
  # Protects against common vulnerabilities like SQL injection, XSS
  rule {
    name     = "aws-managed-core-rule-set"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"

        # Exclude rules that might cause false positives
        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedCoreRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: AWS Managed Rules - Known Bad Inputs
  # Blocks requests with known malicious patterns
  rule {
    name     = "aws-managed-known-bad-inputs"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedKnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  # Rule 5: Block requests with suspicious user agents
  rule {
    name     = "block-suspicious-user-agents"
    priority = 5

    action {
      block {
        custom_response {
          response_code = 403
        }
      }
    }

    statement {
      or_statement {
        statement {
          byte_match_statement {
            search_string = "bot"
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }
        statement {
          byte_match_statement {
            search_string = "crawler"
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }
        statement {
          byte_match_statement {
            search_string = "spider"
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SuspiciousUserAgents"
      sampled_requests_enabled   = true
    }
  }

  # Rule 6: Geo-blocking (optional - customize based on your needs)
  # Example: Only allow specific countries if needed
  # Commented out by default - uncomment and customize if needed
  # rule {
  #   name     = "geo-blocking"
  #   priority = 6
  #
  #   action {
  #     block {}
  #   }
  #
  #   statement {
  #     not_statement {
  #       statement {
  #         geo_match_statement {
  #           country_codes = ["US", "CA", "GB", "AR", "MX", "ES"] # Allowed countries
  #         }
  #       }
  #     }
  #   }
  #
  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "GeoBlocking"
  #     sampled_requests_enabled   = true
  #   }
  # }

  # Custom response bodies
  custom_response_body {
    key          = "rate_limit_response"
    content      = jsonencode({
      error = "Rate limit exceeded. Please try again later."
    })
    content_type = "APPLICATION_JSON"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ContactFormAPIWAF"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "contact-form-api-waf"
  }
}

################################################################################
# WAF Logging Configuration
################################################################################
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  count = var.enable_waf ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.contact_form_api_waf[0].arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group[0].arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "x-api-key"
    }
  }
}

################################################################################
# WAF Association with API Gateway
################################################################################
resource "aws_wafv2_web_acl_association" "api_gateway_waf_association" {
  count = var.enable_waf ? 1 : 0

  resource_arn = module.api_gateway_contact_form.api_arn
  web_acl_arn  = aws_wafv2_web_acl.contact_form_api_waf[0].arn

  depends_on = [
    module.api_gateway_contact_form,
    aws_wafv2_web_acl.contact_form_api_waf
  ]
}
