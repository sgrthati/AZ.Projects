domain_name = "example.int"
region = {
    primary = "ap-south-1"
    secondary = "ap-south-2"
}
api = {
    name = "api"
    stage = "dev"
    supporting_files = "./supporting_files"
    openAPI_spec = "./supporting_files/openAPI.yaml"
    openAPI_spec_2 = "./supporting_files/openAPI2.yaml"
    type = "MOCK"
    path = "api"
}
vpc = {
    jumpbox = {
        cidr_block = "10.0.0.0/16"
        jumpbox_subnet = "10.0.254.0/24"
    }
    primary = {
        cidr_block = "10.1.0.0/16"
        lb_subnet = "10.1.254.0/24"
        api_subnet = "10.1.1.0/24"
    }
    secondary = {
        cidr_block = "10.2.0.0/16"
        lb_subnet = "10.2.254.0/24"
        api_subnet = "10.2.1.0/24"
    }
}