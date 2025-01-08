#aws apigateway get-resources --rest-api-id mhq52jsa4i --region "ap-south-2" --output json | jq .items[1:]

locals {
  openapi_spec = yamldecode(file("${var.api.openAPI_spec}"))
  URL          = local.openapi_spec["servers"][0]["url"]
}
module "import_api" {
  source = "./modules/api"
  region = var.region
  vpc = var.vpc
  api = var.api
}
module "api_operations" {
  source = "./modules/api_operations"
  openapi_yaml = var.api.openAPI_spec
  api_resources_json = var.api.api_resources_json
  rest_api_id = module.import_api.rest_api_id
  region = var.region
  api = var.api
  depends_on = [ module.import_api ]
}
