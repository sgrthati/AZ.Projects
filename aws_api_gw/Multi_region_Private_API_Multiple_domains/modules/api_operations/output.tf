output "primary_invoke_url" {
  value = aws_api_gateway_stage.stage_1.invoke_url
}
output "secondary_invoke_url" {
  value = aws_api_gateway_stage.stage_2.invoke_url
}
output "api_key" {
  value = random_string.api_key.result
}