data "aws_iam_policy_document" "domain_policy_1" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${var.region.primary}:*:/domainnames/*", "arn:aws:execute-api:${var.region.primary}:*:*/*"]

  }
}
data "aws_iam_policy_document" "domain_policy_2" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${var.region.secondary}:*:/domainnames/*", "arn:aws:execute-api:${var.region.secondary}:*:*/*"]

  }
}