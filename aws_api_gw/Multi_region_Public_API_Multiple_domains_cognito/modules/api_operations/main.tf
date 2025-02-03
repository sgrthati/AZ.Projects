locals {
  openapi_spec = yamldecode(file(var.openapi_yaml))
  URL          = local.openapi_spec["servers"][0]["url"]
}
resource "random_string" "api_key" {
  length  = 25
  special = false
}
#Flatten the resources to get a unique combination of resource_id and http_method
locals {
  flattened_resources_1 = flatten([
    for resource in jsondecode(file(var.primary_api_resources_json)): [
      for method, _ in resource.resourceMethods : {
        resource_id  = resource.id
        http_method  = method
        path         = resource.path
      }
    ]
  ])
  flattened_resources_2 = flatten([
    for resource in jsondecode(file(var.secondary_api_resources_json)): [
      for method, _ in resource.resourceMethods : {
        resource_id  = resource.id
        http_method  = method
        path         = resource.path
      }
    ]
  ])
}
#to add backend to existing resources,methods
resource "aws_api_gateway_integration" "get_integration_1" {
  for_each = { for idx, item in local.flattened_resources_1 : 
    "${item.resource_id}_${item.http_method}" => item 
  }
  provider = aws
  rest_api_id             = var.primary_rest_api_id
  resource_id             = each.value.resource_id
  http_method             = each.value.http_method
  integration_http_method = each.value.http_method
  passthrough_behavior    = "WHEN_NO_MATCH"
  type                    = var.api.type
  uri                     = var.api.type == "MOCK" ? null : "${local.URL}${each.value.path}"
  request_templates = {
    "application/json" = <<EOF
    {
      "statusCode": 200
    }
    EOF
  }
  request_parameters = {
    for param in flatten(regexall("/\\{(.*?)\\}", each.value.path)) :
      "integration.request.path.${param}" => "method.request.path.${param}"
  }
  }
resource "aws_api_gateway_integration_response" "int_response_1" {
  for_each = { for idx, item in local.flattened_resources_1 : 
     "${item.resource_id}_${item.http_method}" => item 
  }
  provider = aws
  rest_api_id = var.primary_rest_api_id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = <<EOF
    {
      "statusCode": 200,
      "region": "${var.region.primary}"
    }
    EOF
  }
  depends_on = [ aws_api_gateway_integration.get_integration_1 ]
}
#to enable API-key for each method
resource "null_resource" "enable_api_key_1" {
  for_each = { for idx, item in local.flattened_resources_1 : 
    "${item.resource_id}_${item.http_method}" => item 
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "./supporting_files/update-aws-auth.sh ${var.primary_rest_api_id} ${var.region.primary} ${each.value.resource_id} ${each.value.http_method} ${var.api.api_key} ${aws_api_gateway_authorizer.apigw_authorizer_1.id}"
  }
  depends_on = [ aws_api_gateway_integration.get_integration_1 ]
  triggers = { script_hash = sha256(file("./supporting_files/update-aws-auth.sh")) }
}
#api key
resource "aws_api_gateway_api_key" "api_key_1" {
  provider = aws
  name = "${var.api.name}-api_key" #var.api.name
  description = "API Key for ${var.api.name}"
  value = random_string.api_key.result
  enabled = true
  tags = {
    Name = "${var.api.name}-api_key"
    region = var.region.primary
  }
}
#usage plan
resource "aws_api_gateway_usage_plan" "usage_plan_1" {
  provider = aws
  name = "${var.api.name}-usage_plan"
  description = "Usage Plan for ${var.api.name}"
  api_stages {
    api_id = var.primary_rest_api_id
    stage = aws_api_gateway_stage.stage_1.stage_name
  }
  quota_settings {
    limit = 5000
    offset = 2
    period = "MONTH"
  }
  throttle_settings {
    burst_limit = 100
    rate_limit = 50
  }
  tags = {
    Name = "${var.api.name}-usage_plan"
    region = var.region.primary
  }
}
#binding api key to usage plan
resource "aws_api_gateway_usage_plan_key" "usage_plan_key_1" {
  provider = aws
  key_id = aws_api_gateway_api_key.api_key_1.id
  key_type = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan_1.id
}
resource "aws_api_gateway_domain_name" "name_1" {
  provider = aws
  regional_certificate_arn = var.primary_acm_arn
  domain_name     = "api.${var.domain_name}"
  # policy = data.aws_iam_policy_document.domain_policy_1.json
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_api_gateway_base_path_mapping" "path_mapping_1" {
  provider = aws
  api_id = var.primary_rest_api_id
  stage_name = aws_api_gateway_stage.stage_1.stage_name
  domain_name = aws_api_gateway_domain_name.name_1.domain_name
  domain_name_id = aws_api_gateway_domain_name.name_1.domain_name_id
  base_path = var.api.path
}
resource "aws_api_gateway_rest_api_policy" "policy_1" {
  provider    = aws
  rest_api_id = var.primary_rest_api_id
  policy      = data.aws_iam_policy_document.domain_policy_1.json
  }
resource "aws_api_gateway_method_settings" "metrics_1" {
  rest_api_id = var.primary_rest_api_id
  stage_name  = aws_api_gateway_stage.stage_1.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
    data_trace_enabled = true
  }
}
resource "aws_api_gateway_authorizer" "apigw_authorizer_1" {
  provider = aws
  name          = "apigw_authorizer_1"
  rest_api_id   = var.primary_rest_api_id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_pool_arn]
}
#to deploy the API
resource "aws_api_gateway_deployment" "deployment_1" {
  provider = aws
  rest_api_id = var.primary_rest_api_id
  depends_on = [ null_resource.enable_api_key_1,
  ]
}
resource "aws_cloudwatch_log_group" "log_group_1" {
  name = "/aws/apigateway/${var.api.name}/${var.region.primary}/${var.api.stage}"
}
resource "aws_api_gateway_stage" "stage_1" {
  provider = aws
  deployment_id = aws_api_gateway_deployment.deployment_1.id
  rest_api_id   = var.primary_rest_api_id
  stage_name    = var.api.stage
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.log_group_1.arn
    format = var.custom_log_format
  }
  tags = {
    Name = "${var.api.name}-${var.api.stage}stage"
    region = var.region.primary
  }
}
###############################################################
# Secondary region
###############################################################
#to add backend to existing resources,methods
resource "aws_api_gateway_integration" "get_integration_2" {
  for_each = { for idx, item in local.flattened_resources_2 : 
    "${item.resource_id}_${item.http_method}" => item 
  }
  provider = aws.secondary
  rest_api_id             = var.secondary_rest_api_id
  resource_id             = each.value.resource_id
  http_method             = each.value.http_method
  integration_http_method = each.value.http_method
  passthrough_behavior    = "WHEN_NO_MATCH"
  type                    = var.api.type
  uri                     = var.api.type == "MOCK" ? null : "${local.URL}${each.value.path}"
  request_templates = {
    "application/json" = <<EOF
    {
      "statusCode": 200
    }
    EOF
  }
  request_parameters = {
    for param in flatten(regexall("/\\{(.*?)\\}", each.value.path)) :
      "integration.request.path.${param}" => "method.request.path.${param}"
  }
  }
resource "aws_api_gateway_integration_response" "int_response_2" {
  for_each = { for idx, item in local.flattened_resources_2 : 
     "${item.resource_id}_${item.http_method}" => item 
  }
  provider = aws.secondary
  rest_api_id = var.secondary_rest_api_id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = <<EOF
    {
      "statusCode": 200,
      "region": "${var.region.secondary}"
    }
    EOF
  }
  depends_on = [ aws_api_gateway_integration.get_integration_2,
                 ]
}
#to enable API-key for each method
resource "null_resource" "enable_api_key_2" {
  for_each = { for idx, item in local.flattened_resources_2 : 
    "${item.resource_id}_${item.http_method}" => item 
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "./supporting_files/update-aws-auth.sh ${var.secondary_rest_api_id} ${var.region.secondary} ${each.value.resource_id} ${each.value.http_method} ${var.api.api_key} ${aws_api_gateway_authorizer.apigw_authorizer_2.id}"
  }
  depends_on = [ aws_api_gateway_integration.get_integration_2 ]
  triggers = { script_hash = sha256(file("./supporting_files/update-aws-auth.sh")) }
}
#api key
resource "aws_api_gateway_api_key" "api_key_2" {
  provider = aws.secondary
  name = "${var.api.name}-api_key" #var.api.name
  description = "API Key for ${var.api.name}"
  value = random_string.api_key.result
  enabled = true
  tags = {
    Name = "${var.api.name}-api_key"
    region = var.region.secondary
  }
}
#usage plan
resource "aws_api_gateway_usage_plan" "usage_plan_2" {
  provider = aws.secondary
  name = "${var.api.name}-usage_plan"
  description = "Usage Plan for ${var.api.name}"
  api_stages {
    api_id = var.secondary_rest_api_id
    stage = aws_api_gateway_stage.stage_2.stage_name
  }
  quota_settings {
    limit = 5000
    offset = 2
    period = "MONTH"
  }
  throttle_settings {
    burst_limit = 100
    rate_limit = 50
  }
  tags = {
    Name = "${var.api.name}-usage_plan"
    region = var.region.secondary
  }
}
#binding api key to usage plan
resource "aws_api_gateway_usage_plan_key" "usage_plan_key_2" {
  provider = aws.secondary
  key_id = aws_api_gateway_api_key.api_key_2.id
  key_type = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan_2.id
}
resource "aws_api_gateway_domain_name" "name_2" {
  provider = aws.secondary
  regional_certificate_arn = var.secondary_acm_arn
  domain_name     = "api.${var.domain_name}" 
  # policy = data.aws_iam_policy_document.domain_policy_2.json
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
resource "aws_api_gateway_base_path_mapping" "mapping_2" {
  provider = aws.secondary
  api_id      = var.secondary_rest_api_id
  stage_name  = aws_api_gateway_stage.stage_2.stage_name
  domain_name = aws_api_gateway_domain_name.name_2.domain_name
  domain_name_id = aws_api_gateway_domain_name.name_2.domain_name_id
  base_path = var.api.path
}
resource "aws_api_gateway_authorizer" "apigw_authorizer_2" {
  provider = aws.secondary
  name          = "apigw_authorizer_2"
  rest_api_id   = var.secondary_rest_api_id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_pool_arn]
}
resource "aws_api_gateway_rest_api_policy" "policy_2" {
  provider = aws.secondary
  rest_api_id = var.secondary_rest_api_id
  policy      = data.aws_iam_policy_document.domain_policy_2.json
  }
#to deploy the API
resource "aws_api_gateway_deployment" "deployment_2" {
  provider = aws.secondary
  rest_api_id = var.secondary_rest_api_id
  depends_on = [ null_resource.enable_api_key_2,
  ]
}
resource "aws_cloudwatch_log_group" "log_group_2" {
  provider = aws.secondary
  name = "/aws/apigateway/${var.api.name}/${var.region.secondary}/${var.api.stage}"
}
resource "aws_api_gateway_method_settings" "metrics_2" {
  provider = aws.secondary
  rest_api_id = var.secondary_rest_api_id
  stage_name  = aws_api_gateway_stage.stage_2.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
    data_trace_enabled = true
  }
}
resource "aws_api_gateway_stage" "stage_2" {
  provider = aws.secondary
  deployment_id = aws_api_gateway_deployment.deployment_2.id
  rest_api_id   = var.secondary_rest_api_id
  stage_name    = var.api.stage
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.log_group_2.arn
    format = var.custom_log_format
  }
  tags = {
    Name = "${var.api.name}-${var.api.stage}stage"
    region = var.region.secondary
  }
}
#CNAME FOR LOAD BALANCING
resource "aws_route53_record" "load_Balacing_1" {
  zone_id = var.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  # ttl = "1"
  weighted_routing_policy {
    weight = 1
  }
  alias {
    name = aws_api_gateway_domain_name.name_1.regional_domain_name
    zone_id = aws_api_gateway_domain_name.name_1.regional_zone_id
    evaluate_target_health = false
  }
  set_identifier = var.region.primary
}
resource "aws_route53_record" "load_Balacing_2" {
  provider = aws.secondary
  zone_id = var.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  # ttl = "1"
  weighted_routing_policy {
    weight = 1
  }
  alias {
    name = aws_api_gateway_domain_name.name_2.regional_domain_name
    zone_id = aws_api_gateway_domain_name.name_2.regional_zone_id
    evaluate_target_health = false
  }
  set_identifier = var.region.secondary
}
