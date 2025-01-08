#self signed certificate
resource "tls_private_key" "pvt_key" {
  algorithm = "RSA"
}
resource "tls_self_signed_cert" "cert" {
  private_key_pem       = tls_private_key.pvt_key.private_key_pem
  validity_period_hours = 8760
  subject {
    common_name  = "*.${var.domain_name}" #var.domain_name
    organization = "Internal"
  }
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
    "cert_signing"
  ]
}
resource "aws_acm_certificate" "import_cert_1" {
  provider = aws
  private_key      = tls_private_key.pvt_key.private_key_pem
  certificate_body = tls_self_signed_cert.cert.cert_pem
}
resource "aws_acm_certificate" "import_cert_2" {
  provider = aws.secondary
  private_key      = tls_private_key.pvt_key.private_key_pem
  certificate_body = tls_self_signed_cert.cert.cert_pem
}
resource "aws_route53_zone" "domain" {
  name = var.domain_name
  vpc {
    vpc_id = aws_vpc.vpc_1.id
  }
  tags = {
    Name = var.domain_name
  }
  lifecycle {
    ignore_changes = [ vpc ]
  }
}
resource "aws_route53_zone_association" "zone_association" {
  provider = aws.secondary
  zone_id = aws_route53_zone.domain.zone_id
  vpc_id = aws_vpc.vpc_2.id
}
resource "local_file" "cert" {
  filename = "./supporting_files/${var.domain_name}.crt"
  content = tls_self_signed_cert.cert.cert_pem
}