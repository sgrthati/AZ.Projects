locals {
  openapi_spec = yamldecode(file(var.openapi_yaml))
  URL          = local.openapi_spec["servers"][0]["url"]
}
#Flatten the resources to get a unique combination of resource_id and http_method
locals {
  flattened_resources = flatten([
    for resource in jsondecode(file(var.api_resources_json)): [
      for method, _ in resource.resourceMethods : {
        resource_id  = resource.id
        http_method  = method
        path         = resource.path
      }
    ]
  ])
}
#to add backend to existing resources,methods
resource "aws_api_gateway_integration" "get_integration" {
  for_each = { for idx, item in local.flattened_resources : 
    "${item.resource_id}_${item.http_method}" => item 
  }
  rest_api_id             = var.rest_api_id
  resource_id             = each.value.resource_id
  http_method             = each.value.http_method
  integration_http_method = each.value.http_method
  passthrough_behavior    = "WHEN_NO_MATCH"
  type                    = "HTTP"
  uri                     = "${local.URL}${each.value.path}"
  request_templates = {
    "application/json" = ""
  }
  request_parameters = {
    for param in flatten(regexall("/\\{(.*?)\\}", each.value.path)) :
      "integration.request.path.${param}" => "method.request.path.${param}"
  }
  }
resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  for_each = { for idx, item in local.flattened_resources : 
     "${item.resource_id}_${item.http_method}" => item 
  }
  rest_api_id = var.rest_api_id
  resource_id = each.value.resource_id
  http_method = each.value.http_method
  status_code = "200"

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = ""
  }
  depends_on = [ aws_api_gateway_integration.get_integration ]
}
#to enable API-key for each method
resource "null_resource" "enable_api_key" {
  for_each = { for idx, item in local.flattened_resources : 
    "${item.resource_id}_${item.http_method}" => item 
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "./supporting_files/update-aws-auth.sh ${var.rest_api_id} ${each.value.resource_id} ${each.value.http_method} true"
  }
  depends_on = [ aws_api_gateway_integration.get_integration ]
}

# resource "null_resource" "enable_api_key" {
#   for_each = { for idx, item in local.flattened_resources : 
#     "${item.resource_id}_${item.http_method}" => item 
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command = <<-EOT
#     curl -X PATCH "https://apigateway.${var.region}.amazonaws.com/restapis/${var.rest_api_id}/resources/${each.value.resource_id}/methods/${each.value.http_method}" \
#     -H "Content-Type: application/json" \
#     -H "X-Amz-Date: 20160613T215008Z" \
#     -H "Authorization: AWS4-HMAC-SHA256 Credential=your-access-key/20160613/us-east-1/apigateway/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=your-calculated-signature"
#     -D 
#     EOT
#   }
#   depends_on = [ aws_api_gateway_integration.get_integration ]
# }
#api key
resource "aws_api_gateway_api_key" "api_key" {
  name = "${var.api.name}-api_key" #var.api.name
  description = "API Key for ${var.api.name}"
  enabled = true
  tags = {
    Name = "${var.api.name}-api_key"
  }
}
#usage plan
resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "${var.api.name}-usage_plan"
  description = "Usage Plan for ${var.api.name}"
  api_stages {
    api_id = var.rest_api_id
    stage = var.api.stage
  }
  quota_settings {
    limit = 20
    offset = 2
    period = "MONTH"
  }
  throttle_settings {
    burst_limit = 100
    rate_limit = 50
  }
  tags = {
    Name = "${var.api.name}-usage_plan"
  }
}
#binding api key to usage plan
resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id = aws_api_gateway_api_key.api_key.id
  key_type = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}
#to deploy the API
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [ null_resource.enable_api_key ]
  rest_api_id = var.rest_api_id
}
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = var.rest_api_id
  stage_name    = var.api.stage
}