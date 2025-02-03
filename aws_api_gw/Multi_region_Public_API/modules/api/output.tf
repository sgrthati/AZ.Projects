output "primary_rest_api_id" {
  value = aws_api_gateway_rest_api.api_1.id
}
output "secondary_rest_api_id" {
  value = aws_api_gateway_rest_api.api_2.id  
}
output "primary_api_resources_json" {
  value = local_file.api_resources_json_1.filename
}
output "secondary_api_resources_json" {
  value = local_file.api_resources_json_2.filename  
}
