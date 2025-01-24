#aws apigateway get-resources --rest-api-id mhq52jsa4i --region "ap-south-2" --output json | jq .items[1:]

locals {
  openapi_spec = yamldecode(file("./supporting_files/openAPI.yaml"))
  URL          = local.openapi_spec["servers"][0]["url"]
}
module "import_api" {
  source = "./modules/api"
  openapi_spec = file("./supporting_files/openAPI.yaml")
  api_resources_json = "./supporting_files/api_resources.json"
  region = var.region
  public_key = var.public_key
}
module "api_operations" {
  source = "./modules/api_operations"
  openapi_yaml = "./supporting_files/openAPI.yaml"
  api_resources_json = "./supporting_files/api_resources.json"
  rest_api_id = module.import_api.rest_api_id
  execution_arn = module.import_api.rest_api_execution_arn
  rest_api_name = module.import_api.rest_api_name
  region = var.region
}
