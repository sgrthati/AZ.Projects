output "primary_acm_arn" {
  value = aws_acm_certificate.cert_1.arn
}
output "secondary_acm_arn" {
  value = aws_acm_certificate.cert_2.arn
}
output "zone_id" {
  value = data.aws_route53_zone.zone.id
}