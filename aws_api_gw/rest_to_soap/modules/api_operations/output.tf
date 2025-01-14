output "invoke_api" {
  value = "${aws_api_gateway_stage.stage.invoke_url}"
}