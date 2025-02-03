output "primary_acm_arn" {
  value = aws_acm_certificate.cert_1.arn
}
output "secondary_acm_arn" {
  value = aws_acm_certificate.cert_2.arn
}
output "cognito_pool_id" {
  value = aws_cognito_user_pool.pool.id
}
output "cognito_pool_arn" {
  value = aws_cognito_user_pool.pool.arn
}
output "cognito_client" {
  value = {
    client_id = "${aws_cognito_user_pool_client.pool_client.id}"
    client_secret = "${aws_cognito_user_pool_client.pool_client.client_secret}"
  }  
}
output "zone_id" {
  value = data.aws_route53_zone.zone.id
}