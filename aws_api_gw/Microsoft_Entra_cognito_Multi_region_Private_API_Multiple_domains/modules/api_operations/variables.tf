variable "primary_api_resources_json" {
    type = string
}
variable "secondary_api_resources_json" {
    type = string  
}
variable "region" {
  type = object({
    primary   = string
    secondary = string
  })
}
variable "primary_rest_api_id" {
  type = string
}
variable "secondary_rest_api_id" {
  type = string
}
variable "primary_vpc_endpoint_id" {
  type = string
}
variable "secondary_vpc_endpoint_id" {
  type = string  
}
variable "openapi_yaml" {
  type = string
}
variable "api" {
  type = map  
}
variable "Jumpbox_public_ip" {
  type = string
}
variable "primary_vpc_id" {
  type = string
}
variable "secondary_vpc_id" {
  type = string  
}
variable "domain_name" {
  type = string
}
variable "primary_acm_arn" {
  type = string  
}
variable "secondary_acm_arn" {
  type = string    
}
variable "custom_log_format" {
  type = string
}
variable "cognito_pool_id" {
  type = string
}
variable "cognito_pool_arn" {
  type = string
}