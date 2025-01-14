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
custom_log_format = "{ \"requestId\" : \"$context.requestId\", \"ip\" : \"$context.identity.sourceIp\", \"requestTime\" : \"$context.requestTime\", \"httpMethod\" : \"$context.httpMethod\", \"resourcePath\" : \"$context.resourcePath\", \"status\" : \"$context.status\", \"protocol\" : \"$context.protocol\", \"responseLength\" : \"$context.responseLength\", \"apiId\" : \"$context.apiId\", \"userAgent\" : \"$context.identity.userAgent\", \"resourceId\" : \"$context.resourceId\", \"integrationLatency\" : \"$context.integrationLatency\", \"extendedRequestId\" : \"$context.extendedRequestId\", \"totalLatency\" : \"$context.responseLatency\", \"targetUrl\" : \"$context.method.request.url\", \"proxyUrl\" : \"https://$context.domainName$context.path\" }"

#custom_log_format = { "requestTime": "$context.requestTime", "requestId": "$context.requestId", "httpMethod": "$context.httpMethod", "path": "$context.path", "resourcePath": "$context.resourcePath", "status": "$context.status", "responseLatency": "$context.responseLatency", "xrayTraceId": "$context.xrayTraceId", "wafResponseCode": "$context.wafResponseCode", "integrationLatency": "$context.integration.latency", "integrationServiceStatus": "$context.integration.integrationStatus", "authorizerServiceStatus": "$context.authorizer.status", "authorizerLatency": "$context.authorizer.latency", "ip": "$context.identity.sourceIp", "userAgent": "$context.identity.userAgent", "caller":"$context.identity.caller", "user":"$context.identity.user", "responseLength":"$context.responseLength", "claims": "$context.authorizer.claims.sub", "accountId": "$context.accountId", "apiId": "$context.apiId", "stage": "$context.stage", "errorMessage": "$context.error.message", "intigrationError": "$context.integrationErrorMessage","ResourceId": "$context.resourceId","Domain": "$context.domainName","XRAy_TRACDEID":"$context.xrayTraceId"}