# S3 State Buckets
module "state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.9.0"

  bucket_prefix = "${var.project_name}-terraform-states-"

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  # attach_policy = length(try(each.value.additional_policy_statements,"")) > 0 ? true : false
  # policy        = length(try(each.value.additional_policy_statements,"")) > 0 ? data.aws_iam_policy_document.state_buckets[each.key].json : ""

  object_lock_enabled = true
  object_lock_configuration = {
    object_lock_enabled = "Enabled"
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 440
      }
    }
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        # kms_master_key_id = aws_kms_key.objects.arn
        sse_algorithm = "aws:kms"
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

      expiration = {
        days = 360 * 2
        # expired_object_delete_marker = true
      }

      noncurrent_version_expiration = {
        newer_noncurrent_versions = 10
        days                      = 180
      }
    }
  ]
}
