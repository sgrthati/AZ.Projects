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
  region = var.region
  domain_name = var.domain_name
}
module "import_api" {
  source = "./modules/api"
  providers = {
    aws   = aws
    aws.secondary = aws.secondary
  }
  region = var.region
  api = var.api
  domain_name = var.domain_name
  zone_id = module.base.zone_id
}
module "api_operations" {
  source = "./modules/api_operations"
  providers = {
    aws   = aws
    aws.secondary = aws.secondary
  }
  openapi_yaml = var.api.openAPI_spec
  primary_api_resources_json = "${module.import_api.primary_api_resources_json}"
  secondary_api_resources_json = "${module.import_api.secondary_api_resources_json}"
  primary_rest_api_id = module.import_api.primary_rest_api_id
  secondary_rest_api_id = module.import_api.secondary_rest_api_id
  primary_acm_arn = module.base.primary_acm_arn
  secondary_acm_arn = module.base.secondary_acm_arn
  custom_log_format = var.custom_log_format
  domain_name = var.domain_name
  zone_id = module.base.zone_id
  region = var.region
  api = var.api
}
