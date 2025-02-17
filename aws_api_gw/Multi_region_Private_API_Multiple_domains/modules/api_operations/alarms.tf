resource "aws_cloudwatch_metric_alarm" "gateway_error_rate_1" {
  provider            = aws
  alarm_name          = "${var.api.name}-${var.region.primary}-gateway-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "Gateway error rate has exceeded threshold"
  treat_missing_data  = "missing"
  metric_name         = "4xx"
  namespace           = "AWS/ApiGateway"
  period              = 10
  evaluation_periods  = 1
  threshold           = 1
  statistic           = "Sum"
  datapoints_to_alarm = 1

  dimensions = {
    ApiId = var.primary_rest_api_id
    Stage = aws_api_gateway_stage.stage_1.stage_name
  }
}
resource "aws_cloudwatch_metric_alarm" "gateway_error_rate_2" {
  provider            = aws.secondary
  alarm_name          = "${var.api.name}-${var.region.primary}-gateway-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "Gateway error rate has exceeded threshold"
  treat_missing_data  = "missing"
  metric_name         = "4xx"
  namespace           = "AWS/ApiGateway"
  period              = 10
  evaluation_periods  = 1
  threshold           = 1
  statistic           = "Sum"
  datapoints_to_alarm = 1

  dimensions = {
    ApiId = var.secondary_rest_api_id
    Stage = aws_api_gateway_stage.stage_2.stage_name
  }
}