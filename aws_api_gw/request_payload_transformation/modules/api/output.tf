output "rest_api_id" {
  value = aws_api_gateway_rest_api.api.id
}
output "rest_api_name" {
  value = aws_api_gateway_rest_api.api.name
}
output "rest_api_execution_arn" {
  value = aws_api_gateway_rest_api.api.execution_arn
}
output "api_resources_json" {
  value = var.api_resources_json  
}