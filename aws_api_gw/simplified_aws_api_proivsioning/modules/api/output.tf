output "rest_api_id" {
  value = aws_api_gateway_rest_api.api.id
}
output "api_resources_json" {
  value = var.api_resources_json  
}