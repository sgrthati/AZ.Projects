#to create api along with resources,methods
resource "aws_api_gateway_rest_api" "api_1" {
  provider = aws
  name = "${var.api.name}-${var.region.primary}"
  body = file("${var.api.openAPI_spec}")
  put_rest_api_mode = "merge"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Name = var.api.name
    region = var.region.primary
  }
}
resource "null_resource" "sleep_1" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [ aws_api_gateway_rest_api.api_1 ] 
}
resource "local_file" "api_resources_json_1" {
  filename = "${var.api.supporting_files}/${var.api.name}-${var.region.primary}-resources.json"
  content = "{}"
  provisioner "local-exec" {
    interpreter = [ "bash", "-c" ]
    command = "aws apigateway get-resources --rest-api-id ${aws_api_gateway_rest_api.api_1.id} --region ${var.region.primary} --output json | jq '.items | map(select(.path != \"/\"))' > ${var.api.supporting_files}/${var.api.name}-${var.region.primary}-resources.json"
    when = create
  }
  provisioner "local-exec" {
    interpreter = [ "bash", "-c"]
    command = "echo '{}' > ${self.filename}"
    when = destroy
  }
  depends_on = [ null_resource.sleep_1, aws_api_gateway_rest_api.api_1 ]
}
######################################################
# Secondary region
######################################################
#to create api along with resources,methods
resource "aws_api_gateway_rest_api" "api_2" {
  provider = aws.secondary
  name = "${var.api.name}-${var.region.secondary}"
  body = file("${var.api.openAPI_spec_2}")
  put_rest_api_mode = "merge"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Name = var.api.name
    region = var.region.secondary
  }
}
resource "null_resource" "sleep_2" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [ aws_api_gateway_rest_api.api_2 ] 
}
resource "local_file" "api_resources_json_2" {
  filename = "${var.api.supporting_files}/${var.api.name}-${var.region.secondary}-resources.json"
  content = "{}"
  provisioner "local-exec" {
    interpreter = [ "bash", "-c" ]
    command = "aws apigateway get-resources --rest-api-id ${aws_api_gateway_rest_api.api_2.id} --region ${var.region.secondary} --output json | jq '.items | map(select(.path != \"/\"))' > ${var.api.supporting_files}/${var.api.name}-${var.region.secondary}-resources.json"
    when = create
  }
  provisioner "local-exec" {
    interpreter = [ "bash", "-c"]
    command = "echo '{}' > ${self.filename}"
    when = destroy
  }
  depends_on = [ null_resource.sleep_2, aws_api_gateway_rest_api.api_2 ]
}
