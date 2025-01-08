region = "ap-south-2"
api = {
    name = "aws-api-gw"
    stage = "dev"
    api_resources_json = "./supporting_files/api_resources.json"
    openAPI_spec = "./supporting_files/openAPI.yaml"
}
vpc = {
    cidr_block = "10.0.0.0/16"
    api_subnet = "10.0.1.0/24"
    jumpbox_subnet = "10.0.2.0/24"
}