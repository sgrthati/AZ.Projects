data "aws_iam_policy_document" "apigw" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["execute-api:Invoke"]
    resources = ["*"]
  }
  statement {
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["execute-api:Invoke"]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values = [aws_vpc_endpoint.vpc_endpoint.id]
    }
  }
}
#to create api along with resources,methods
resource "aws_api_gateway_rest_api" "api" {
  name = var.api.name
  body = file("${var.api.openAPI_spec}")
  put_rest_api_mode = "merge"
  policy = data.aws_iam_policy_document.apigw.json
  endpoint_configuration {
    types = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.vpc_endpoint.id]
  }
}
resource "null_resource" "sleep" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [ aws_api_gateway_rest_api.api ] 
}
resource "local_file" "api_resources_json" {
  filename = var.api.api_resources_json
  content = "{}"
  provisioner "local-exec" {
    interpreter = [ "bash", "-c" ]
    command = "aws apigateway get-resources --rest-api-id ${aws_api_gateway_rest_api.api.id} --region ${var.region} --output json | jq '.items | map(select(.path != \"/\"))' > ${var.api.api_resources_json}"
    when = create
  }
  provisioner "local-exec" {
    interpreter = [ "bash", "-c"]
    command = "echo '{}' > ${self.filename}"
    when = destroy
  }
  depends_on = [ null_resource.sleep, aws_api_gateway_rest_api.api ]
}
