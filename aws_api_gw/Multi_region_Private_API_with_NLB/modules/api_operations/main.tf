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
    command = "./supporting_files/update-aws-auth.sh ${var.primary_rest_api_id} ${var.region.primary} ${each.value.resource_id} ${each.value.http_method} true"
  }
  depends_on = [ aws_api_gateway_integration.get_integration_1 ]
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
  certificate_arn = var.primary_acm_arn
  domain_name     = "api1.${var.domain_name}"
  policy = data.aws_iam_policy_document.domain_policy_1.json
  endpoint_configuration {
    types = ["PRIVATE"]
  }
}
resource "aws_api_gateway_domain_name_access_association" "domain_association_1" {
  provider = aws
  access_association_source = var.primary_vpc_endpoint_id
  access_association_source_type = "VPCE"
  domain_name_arn = aws_api_gateway_domain_name.name_1.arn
}
resource "aws_api_gateway_base_path_mapping" "path_mapping_1" {
  provider = aws
  api_id = var.primary_rest_api_id
  domain_name = aws_api_gateway_domain_name.name_1.domain_name
  domain_name_id = aws_api_gateway_domain_name.name_1.domain_name_id
  base_path = var.api.path
}
resource "aws_api_gateway_domain_name" "name_1_1" {
  provider = aws
  certificate_arn = var.primary_acm_arn
  domain_name     = "api.${var.domain_name}"
  policy = data.aws_iam_policy_document.domain_policy_1.json
  endpoint_configuration {
    types = ["PRIVATE"]
  }
}
resource "aws_api_gateway_domain_name_access_association" "domain_association_1_1" {
  provider = aws
  access_association_source = var.primary_vpc_endpoint_id
  access_association_source_type = "VPCE"
  domain_name_arn = aws_api_gateway_domain_name.name_1_1.arn
}
resource "aws_api_gateway_base_path_mapping" "path_mapping_1_1" {
  provider = aws
  api_id = var.primary_rest_api_id
  stage_name = aws_api_gateway_stage.stage_1.stage_name
  domain_name = aws_api_gateway_domain_name.name_1_1.domain_name
  domain_name_id = aws_api_gateway_domain_name.name_1_1.domain_name_id
  base_path = var.api.path
}
resource "aws_api_gateway_rest_api_policy" "policy_1" {
  provider    = aws
  rest_api_id = var.primary_rest_api_id
  policy      = data.aws_iam_policy_document.policy_1.json
  }
#to deploy the API
resource "aws_api_gateway_deployment" "deployment_1" {
  provider = aws
  rest_api_id = var.primary_rest_api_id
  depends_on = [ null_resource.enable_api_key_1,
  aws_api_gateway_domain_name.name_1,
  aws_api_gateway_domain_name_access_association.domain_association_1,
  aws_api_gateway_rest_api_policy.policy_1,
  aws_api_gateway_domain_name.name_1_1,
  aws_api_gateway_domain_name_access_association.domain_association_1_1
  ]
}
resource "aws_api_gateway_stage" "stage_1" {
  provider = aws
  deployment_id = aws_api_gateway_deployment.deployment_1.id
  rest_api_id   = var.primary_rest_api_id
  stage_name    = var.api.stage
  tags = {
    Name = "${var.api.name}-${var.api.stage}stage"
    region = var.region.primary
  }
  lifecycle {
    create_before_destroy = true
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
  depends_on = [ aws_api_gateway_integration.get_integration_2 ]
}
#to enable API-key for each method
resource "null_resource" "enable_api_key_2" {
  for_each = { for idx, item in local.flattened_resources_2 : 
    "${item.resource_id}_${item.http_method}" => item 
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "./supporting_files/update-aws-auth.sh ${var.secondary_rest_api_id} ${var.region.secondary} ${each.value.resource_id} ${each.value.http_method} true"
  }
  depends_on = [ aws_api_gateway_integration.get_integration_2 ]
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
  certificate_arn = var.secondary_acm_arn
  domain_name     = "api2.${var.domain_name}" 
  policy = data.aws_iam_policy_document.domain_policy_2.json
  endpoint_configuration {
    types = ["PRIVATE"]
  }
}
resource "aws_api_gateway_domain_name_access_association" "domain_association_2" {
  provider = aws.secondary
  access_association_source = var.secondary_vpc_endpoint_id
  access_association_source_type = "VPCE"
  domain_name_arn = aws_api_gateway_domain_name.name_2.arn
}
resource "aws_api_gateway_base_path_mapping" "mapping_2" {
  provider = aws.secondary
  api_id      = var.secondary_rest_api_id
  stage_name  = aws_api_gateway_stage.stage_2.stage_name
  domain_name = aws_api_gateway_domain_name.name_2.domain_name
  domain_name_id = aws_api_gateway_domain_name.name_2.domain_name_id
  base_path = var.api.path
}
resource "aws_api_gateway_domain_name" "name_2_1" {
  provider = aws.secondary
  certificate_arn = var.secondary_acm_arn
  domain_name     = "api.${var.domain_name}"
  policy = data.aws_iam_policy_document.domain_policy_2.json
  endpoint_configuration {
    types = ["PRIVATE"]
  }
}
resource "aws_api_gateway_domain_name_access_association" "domain_association_2_1" {
  provider = aws.secondary
  access_association_source = var.secondary_vpc_endpoint_id
  access_association_source_type = "VPCE"
  domain_name_arn = aws_api_gateway_domain_name.name_2_1.arn
}
resource "aws_api_gateway_base_path_mapping" "path_mapping_2_1" {
  provider = aws.secondary
  api_id      = var.secondary_rest_api_id
  stage_name  = aws_api_gateway_stage.stage_2.stage_name
  domain_name_id = aws_api_gateway_domain_name.name_2_1.domain_name_id
  domain_name = aws_api_gateway_domain_name.name_2_1.domain_name
  base_path = var.api.path
  depends_on = [ aws_api_gateway_domain_name.name_2_1 ]
}
resource "aws_api_gateway_rest_api_policy" "policy_2" {
  provider = aws.secondary
  rest_api_id = var.secondary_rest_api_id
  policy      = data.aws_iam_policy_document.policy_2.json
  }
#to deploy the API
resource "aws_api_gateway_deployment" "deployment_2" {
  provider = aws.secondary
  rest_api_id = var.secondary_rest_api_id
  depends_on = [ null_resource.enable_api_key_2,
    aws_api_gateway_domain_name.name_2,
    aws_api_gateway_domain_name_access_association.domain_association_2,
    aws_api_gateway_rest_api_policy.policy_2,
    aws_api_gateway_domain_name.name_2_1,
    aws_api_gateway_domain_name_access_association.domain_association_2_1
  ]
}
resource "aws_api_gateway_stage" "stage_2" {
  provider = aws.secondary
  deployment_id = aws_api_gateway_deployment.deployment_2.id
  rest_api_id   = var.secondary_rest_api_id
  stage_name    = var.api.stage
  tags = {
    Name = "${var.api.name}-${var.api.stage}stage"
    region = var.region.secondary
  }
}
