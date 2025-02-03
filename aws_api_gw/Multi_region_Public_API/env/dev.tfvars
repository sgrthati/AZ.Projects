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
    primary = {
        cidr_block = "10.0.0.0/16"
        lb_subnet_1 = "10.0.254.0/24"
        lb_subnet_2 = "10.0.253.0/24"
        api_subnet = "10.0.1.0/24"
        jumpbox_subnet = "10.0.2.0/24"
    }
    secondary = {
        cidr_block = "192.168.0.0/16"
        lb_subnet_1 = "192.168.254.0/24"
        lb_subnet_2 = "192.168.253.0/24"
        api_subnet = "192.168.1.0/24"
    }
}