output "Jumpbox_public_ip" {
  value = aws_instance.jumpbox.public_ip  
}
output "primary_vpc_id" {
  value = aws_vpc.vpc_1.id
}
output "secondary_vpc_id" {
  value = aws_vpc.vpc_2.id
}
output "primary_api_subnet" {
  value = aws_subnet.api_subnet_1.id
}
output "secondary_api_subnet" {
  value = aws_subnet.api_subnet_2.id
}
output "primary_api_sg_id" {
  value = aws_security_group.api_sg.id
}
output "secondary_api_sg_id" {
  value = aws_security_group.api_sg_2.id
}
output "jumpbox" {
  value = aws_instance.jumpbox.public_ip
}
output "primary_lb_arn" {
  value = aws_lb.nlb_1.arn
}
output "secondary_lb_arn" {
  value = aws_lb.nlb_2.arn  
}
output "primary_acm_arn" {
  value = aws_acm_certificate.import_cert_1.arn
}
output "secondary_acm_arn" {
  value = aws_acm_certificate.import_cert_2.arn
}
output "primary_lb_tg_arn" {
  value = aws_lb_target_group.tg_1.arn
}
output "secondary_lb_tg_arn" {
  value = aws_lb_target_group.tg_2.arn
}
output "primary_vpc_endpoint_ip" {
  value = data.aws_network_interface.nic_1.private_ip
}
output "secondary_vpc_endpoint_ip" {
  value = data.aws_network_interface.nic_2.private_ip
}
output "primary_vpc_endpoint_id" {
  value = aws_vpc_endpoint.vpc_endpoint_1.id
}
output "secondary_vpc_endpoint_id" {
  value = aws_vpc_endpoint.vpc_endpoint_2.id
}