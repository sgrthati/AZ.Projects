#aws apigateway get-resources --rest-api-id mhq52jsa4i --region "ap-south-2" --output json | jq .items[1:]
locals {
  openapi_spec = yamldecode(file("${var.api.openAPI_spec}"))
  URL          = local.openapi_spec["servers"][0]["url"]
}
module "base" {
  source = "./modules/base"
  providers = {
    aws   = aws
    aws.secondary = aws.secondary
  }
  api = var.api
  vpc = var.vpc
  region = var.region
  domain_name = var.domain_name
  cognito = var.cognito
}
module "import_api" {
  source = "./modules/api"
  providers = {
    aws   = aws
    aws.secondary = aws.secondary
  }
  region = var.region
  api = var.api
  primary_vpc_id = module.base.primary_vpc_id
  secondary_vpc_id = module.base.secondary_vpc_id
  primary_api_subnet_id = module.base.primary_api_subnet
  secondary_api_subnet_id = module.base.secondary_api_subnet
  primary_api_sg_id = module.base.primary_api_sg_id
  secondary_api_sg_id = module.base.secondary_api_sg_id
  primary_lb_arn = module.base.primary_lb_arn
  secondary_lb_arn = module.base.secondary_lb_arn
  primary_lb_tg_arn = module.base.primary_lb_tg_arn
  secondary_lb_tg_arn = module.base.secondary_lb_tg_arn
  primary_vpc_endpoint_ip = module.base.primary_vpc_endpoint_ip
  secondary_vpc_endpoint_ip = module.base.secondary_vpc_endpoint_ip
  primary_vpc_endpoint_id = module.base.primary_vpc_endpoint_id
  secondary_vpc_endpoint_id = module.base.secondary_vpc_endpoint_id
  domain_name = var.domain_name
}
module "api_operations" {
  source = "./modules/api_operations"
  providers = {
    aws   = aws
    aws.secondary = aws.secondary
  }
  primary_vpc_endpoint_id = module.base.primary_vpc_endpoint_id
  secondary_vpc_endpoint_id = module.base.secondary_vpc_endpoint_id
  openapi_yaml = var.api.openAPI_spec
  primary_api_resources_json = "${module.import_api.primary_api_resources_json}"
  secondary_api_resources_json = "${module.import_api.secondary_api_resources_json}"
  primary_rest_api_id = module.import_api.primary_rest_api_id
  secondary_rest_api_id = module.import_api.secondary_rest_api_id
  primary_vpc_id = module.base.primary_vpc_id
  secondary_vpc_id = module.base.secondary_vpc_id
  Jumpbox_public_ip   = module.base.jumpbox
  primary_acm_arn = module.base.primary_acm_arn
  secondary_acm_arn = module.base.secondary_acm_arn
  custom_log_format = var.custom_log_format
  domain_name = var.domain_name
  cognito_pool_arn = module.base.cognito_pool_arn
  cognito_pool_id = module.base.cognito_pool_id
  region = var.region
  api = var.api
}
