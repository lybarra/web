module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "5.48.0"
}

module "pipeline_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.48.0"

  name = "web-pipeline-iam-role"

  subjects = var.oidc_subjects

  policies = {
    pipeline_policy = aws_iam_policy.pipeline_policy.arn
  }

}

resource "aws_iam_policy" "pipeline_policy" {
  name        = "pipeline_additional_policy"
  description = "Additional policy permissions for the pipeline"
  policy      = data.aws_iam_policy_document.pipeline_policy.json
}

data "aws_iam_policy_document" "pipeline_policy" {

  statement {
    sid     = "webS3BucketObjects"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "${module.web_bucket.s3_bucket_arn}/*"
    ]
  }
  statement {
    sid     = "webS3Bucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.web_bucket.s3_bucket_arn,
    ]
  }
  statement {
    sid     = "cloudfront"
    effect  = "Allow"
    actions = ["cloudfront:CreateInvalidation"]
    resources = [
      "arn:aws:cloudfront::*:distribution/*",
    ]
  }
}
