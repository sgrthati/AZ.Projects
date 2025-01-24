data "aws_caller_identity" "current" {}
data "aws_route53_zone" "domain" {
  name         = "${var.domain_name}"
  private_zone = true
}
data "aws_iam_policy_document" "policy_1" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${var.region.primary}:*:/domainnames/*", "arn:aws:execute-api:${var.region.primary}:*:*/*"]
    # condition {
    #   test     = "ArnEquals"
    #   variable = "execute-api:viaDomainArn"
    #   values = ["arn:aws:execute-api:${var.region.primary}:*:/domainnames/*"]
    # }
  }
  # statement {
  #   effect = "Deny"
  #   principals {
  #     type        = "AWS"
  #     identifiers = ["*"]
  #   }
  #   actions = ["execute-api:Invoke"]
  #   resources = ["*"]
  #   condition {
  #     test     = "StringNotEquals"
  #     variable = "aws:SourceVpce"
  #     values = [var.primary_vpc_id]
  #   }
  # }
}
data "aws_iam_policy_document" "policy_2" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${var.region.secondary}:*:/domainnames/*", "arn:aws:execute-api:${var.region.secondary}:*:*/*"]
    # condition {
    #   test     = "ArnEquals"
    #   variable = "execute-api:viaDomainArn"
    #   values = ["arn:aws:execute-api:${var.region.secondary}:*:/domainnames/*"]
    # }
  }
  # statement {
  #   effect = "Deny"
  #   principals {
  #     type        = "AWS"
  #     identifiers = ["*"]
  #   }
  #   actions = ["execute-api:Invoke"]
  #   resources = ["*"]
  #   condition {
  #     test     = "StringNotEquals"
  #     variable = "aws:SourceVpce"
  #     values = [var.secondary_vpc_id]
  #   }
  # }
}
data "aws_iam_policy_document" "domain_policy_1" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${var.region.primary}:*:/domainnames/*", "arn:aws:execute-api:${var.region.primary}:*:*/*"]
    # condition {
    #   test     = "ArnEquals"
    #   variable = "execute-api:viaDomainArn"
    #   values = ["arn:aws:execute-api:${var.region.primary}:*:/domainnames/*"]
    # }
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
    # condition {
    #   test     = "ArnEquals"
    #   variable = "execute-api:viaDomainArn"
    #   values = ["arn:aws:execute-api:${var.region.secondary}:*:/domainnames/*"]
    # }
  }
}