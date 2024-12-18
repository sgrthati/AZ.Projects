#to create api along with resources,methods
resource "aws_api_gateway_rest_api" "api" {
  name = "aws_api_gw"
  body = var.openapi_spec
  put_rest_api_mode = "merge"
}
resource "null_resource" "sleep" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [ aws_api_gateway_rest_api.api ] 
}
resource "local_file" "api_resources_json" {
  filename = var.api_resources_json
  content = "{}"
  provisioner "local-exec" {
    interpreter = [ "bash", "-c" ]
    command = "aws apigateway get-resources --rest-api-id ${aws_api_gateway_rest_api.api.id} --region ${var.region} --output json | jq '.items | map(select(.path != \"/\"))' > ${var.api_resources_json}"
    when = create
  }
  provisioner "local-exec" {
    interpreter = [ "bash", "-c"]
    command = "echo '{}' > ${self.filename}"
    when = destroy
  }
  depends_on = [ null_resource.sleep, aws_api_gateway_rest_api.api ]
}
