data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}
resource "aws_iam_role" "cloudwatch" {
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
resource "aws_api_gateway_account" "cloud_watch_1" {
  provider = aws
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}
resource "aws_iam_role_policy" "cloudwatch_1" {
  provider = aws
  name   = "api_gw_cloud_watch_policy"
  role   = aws_iam_role.cloudwatch.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}
resource "aws_api_gateway_account" "cloud_watch_2" {
  provider = aws.secondary
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}
resource "aws_iam_role_policy" "cloudwatch_2" {
  provider = aws.secondary
  name   = "api_gw_cloud_watch_policy"
  role   = aws_iam_role.cloudwatch.id
  policy = data.aws_iam_policy_document.cloudwatch.json
}