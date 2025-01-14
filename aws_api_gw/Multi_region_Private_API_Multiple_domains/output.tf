output "invoke_primary_api" {
  value = module.api_operations.primary_invoke_url
}
output "invoke_secondary_api" {
  value = module.api_operations.secondary_invoke_url
}
output "api_key" {
  value = module.api_operations.api_key
}
output "invoke_1" {
  value = "curl -v -H 'x-api-key: ${module.api_operations.api_key}' https://api1.${var.domain_name}/api/region"
}
output "invoke_2" {
  value = "curl -v -H 'x-api-key: ${module.api_operations.api_key}' https://api2.${var.domain_name}/api/region"
}
output "Invoke" {
  value = "curl -v -H 'x-api-key: ${module.api_operations.api_key}' https://api.${var.domain_name}/api/region"
}
output "multi_calls" {
  value = "for((i=0; i<10; i++)); do curl -H 'x-api-key: ${module.api_operations.api_key}' https://api.${var.domain_name}/api/region; done"
}
output "Jumpbox_public_ip" {
  value = module.base.Jumpbox_public_ip
}