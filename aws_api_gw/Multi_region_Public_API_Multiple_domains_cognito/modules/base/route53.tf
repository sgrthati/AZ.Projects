#domain
data "aws_route53_zone" "zone" {
  name         = var.domain_name
  private_zone = false
}
#acm cert creation
resource "aws_acm_certificate" "cert_1" {
  provider = aws
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
#creating DNS Record for Cert validation
resource "aws_route53_record" "cert_dns_1" {
  provider = aws
  allow_overwrite = true
  name =  tolist(aws_acm_certificate.cert_1.domain_validation_options)[0].resource_record_name
  records = [tolist(aws_acm_certificate.cert_1.domain_validation_options)[0].resource_record_value]
  type = tolist(aws_acm_certificate.cert_1.domain_validation_options)[0].resource_record_type
  zone_id = data.aws_route53_zone.zone.zone_id
  ttl = 60
}
#validating cert
resource "aws_acm_certificate_validation" "cert_validate_1" {
  provider = aws
  certificate_arn = aws_acm_certificate.cert_1.arn
  validation_record_fqdns = [aws_route53_record.cert_dns_1.fqdn]
}
#acm cert creation
resource "aws_acm_certificate" "cert_2" {
  provider = aws.secondary
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
#creating DNS Record for Cert validation
resource "aws_route53_record" "cert_dns_2" {
  provider = aws.secondary
  allow_overwrite = true
  name =  tolist(aws_acm_certificate.cert_2.domain_validation_options)[0].resource_record_name
  records = [tolist(aws_acm_certificate.cert_2.domain_validation_options)[0].resource_record_value]
  type = tolist(aws_acm_certificate.cert_2.domain_validation_options)[0].resource_record_type
  zone_id = data.aws_route53_zone.zone.zone_id
  ttl = 60
}
#validating cert
resource "aws_acm_certificate_validation" "cert_validate_2" {
  provider = aws.secondary
  certificate_arn = aws_acm_certificate.cert_2.arn
  validation_record_fqdns = [aws_route53_record.cert_dns_2.fqdn]
}
# resource "aws_api_gateway_domain_name" "name_1" {
#   provider = aws
#   regional_certificate_arn = aws_acm_certificate.cert_1.arn
#   domain_name     = "api.${var.domain_name}"
#   policy = data.aws_iam_policy_document.domain_policy_1.json
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
#   depends_on = [ aws_acm_certificate_validation.cert_validate_1 ]
# }
# resource "aws_api_gateway_domain_name" "name_2" {
#   provider = aws.secondary
#   regional_certificate_arn = aws_acm_certificate.cert_2.arn
#   domain_name     = "api.${var.domain_name}" 
#   policy = data.aws_iam_policy_document.domain_policy_2.json
#   endpoint_configuration {
#     types = ["REGIONAL"]
#   }
#   depends_on = [ aws_acm_certificate_validation.cert_validate_2 ]
# }