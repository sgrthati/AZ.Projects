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
    "application/json" = "${each.value.http_method == "POST" ? file("./supporting_files/transformer-template.json") : "" }"
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
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = var.rest_api_id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
    data_trace_enabled = true
  }
}
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = var.rest_api_id
  depends_on = [ aws_api_gateway_integration.get_integration,
                aws_api_gateway_integration_response.MyDemoIntegrationResponse,
   ]
}
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = var.rest_api_id
  stage_name    = "dev"
}