#primary region vpc module
resource "aws_vpc" "vpc_1" {
  provider = aws
  cidr_block = var.vpc.primary.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "api-vpc-${var.region.primary}"
    region = var.region.primary
  }
}
data "aws_availability_zones" "available_1" {
  provider = aws
}
resource "aws_subnet" "api_subnet_1" {
  provider = aws
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = var.vpc.primary.api_subnet
  availability_zone = data.aws_availability_zones.available_1.names[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "${aws_vpc.vpc_1.tags.Name}-api-subnet"
    region = var.region.primary
  }
}
resource "aws_subnet" "lb_subnet_1_1" {
  provider = aws
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = var.vpc.primary.lb_subnet_1
  availability_zone = data.aws_availability_zones.available_1.names[0]
  tags = {
    Name = "lb-subnet-1-1"
    region = var.region.primary
  }
}
resource "aws_subnet" "lb_subnet_1_2" {
  provider = aws
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = var.vpc.primary.lb_subnet_2
  availability_zone = data.aws_availability_zones.available_1.names[1]
  tags = {
    Name = "lb-subnet-1-2"
    region = var.region.primary
  }
}
resource "aws_security_group" "api_sg" {
  provider = aws
  vpc_id = aws_vpc.vpc_1.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "api-sg"
    region = var.region.primary
    "Security group name" = "api-sg"
  }
}
resource "aws_lb" "nlb_1" {
  provider = aws
  name = "${var.api.name}-lb-${var.region.primary}"
  internal = true
  load_balancer_type = "application"
  subnets = [aws_subnet.lb_subnet_1_1.id, aws_subnet.lb_subnet_1_2.id]
  security_groups = [aws_security_group.api_sg.id]
  tags = {
    Name = "${var.api.name}-${var.region.primary}-lb"
    region = var.region.primary
  }
}
resource "aws_lb_target_group" "tg_1" {
  provider = aws
  name     = "${var.api.name}-${var.region.primary}-tg"
  port     = 443
  protocol = "HTTPS"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc_1.id
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher = "200,403"
  }
}
resource "aws_lb_listener" "aws_lb_listener_1" {
  provider = aws
  load_balancer_arn = aws_lb.nlb_1.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.import_cert_1.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_1.arn
  }
  tags = {
    Name = "${var.api.name}-${var.region.primary}-listener"
    region = var.region.primary
  }
}
resource "aws_lb_listener_rule" "rule_1" {
  provider = aws
  listener_arn = aws_lb_listener.aws_lb_listener_1.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_1.arn
  }
  condition {
    path_pattern {
      values = ["/${var.api.name}/*"]
    }
  }
}
resource "aws_route53_record" "record_1" {
  provider = aws
  zone_id = aws_route53_zone.domain.zone_id
  name    = "api1.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.nlb_1.dns_name
    zone_id                = aws_lb.nlb_1.zone_id
    evaluate_target_health = false
  }
}
data "aws_vpc_endpoint_service" "service_1" {
  provider = aws
  service = "execute-api"
}
resource "aws_vpc_endpoint" "vpc_endpoint_1" {
  provider = aws
  vpc_id              = aws_vpc.vpc_1.id
  service_name        = data.aws_vpc_endpoint_service.service_1.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.api_subnet_1.id]
  security_group_ids = [aws_security_group.api_sg.id]
  tags = {
    name = "${var.api.name}-vpc-endpoint-${var.region.primary}"
    region = var.region.primary
  }
}
data "aws_network_interface" "nic_1" {
  provider = aws
  id = tolist(aws_vpc_endpoint.vpc_endpoint_1.network_interface_ids)[0]
}
##############################################
#secondery region
##############################################
resource "aws_vpc" "vpc_2" {
  provider = aws.secondary
  cidr_block = var.vpc.secondary.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "api-vpc-${var.region.secondary}"
    region = var.region.secondary
  }
}
data "aws_availability_zones" "available_2" {
  provider = aws.secondary
}
resource "aws_subnet" "api_subnet_2" {
  provider = aws.secondary
  vpc_id            = aws_vpc.vpc_2.id
  cidr_block        = var.vpc.secondary.api_subnet
  availability_zone = data.aws_availability_zones.available_2.names[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "${aws_vpc.vpc_2.tags.Name}-api-subnet"
    region = var.region.secondary
  }
}
resource "aws_subnet" "lb_subnet_2_1" {
  provider = aws.secondary
  vpc_id            = aws_vpc.vpc_2.id
  cidr_block        = var.vpc.secondary.lb_subnet_1
  availability_zone = data.aws_availability_zones.available_2.names[0]
  tags = {
    Name = "lb-subnet-2-1"
    region = var.region.secondary
  }
}
resource "aws_subnet" "lb_subnet_2_2" {
  provider = aws.secondary
  vpc_id            = aws_vpc.vpc_2.id
  cidr_block        = var.vpc.secondary.lb_subnet_2
  availability_zone = data.aws_availability_zones.available_2.names[1]
  tags = {
    Name = "lb-subnet-2-2"
    region = var.region.secondary
  }
}

resource "aws_security_group" "api_sg_2" {
  provider = aws.secondary
  vpc_id = aws_vpc.vpc_2.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "api-sg"
    region = var.region.secondary
    "Security group name" = "api-sg"
  }
}
resource "aws_lb" "nlb_2" {
  provider = aws.secondary
  name = "${var.api.name}-lb-${var.region.secondary}"
  internal = true
  load_balancer_type = "application"
  security_groups = [aws_security_group.api_sg_2.id]
  subnets = [aws_subnet.lb_subnet_2_1.id, aws_subnet.lb_subnet_2_2.id]
  tags = {
    Name = "${var.api.name}-${var.region.secondary}-lb"
    region = var.region.secondary
  }
}
resource "aws_lb_target_group" "tg_2" {
  provider = aws.secondary
  name     = "${var.api.name}-${var.region.secondary}-tg"
  port     = 443
  protocol = "HTTPS"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc_2.id
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher = "200,403"
  }
}
resource "aws_lb_listener" "aws_lb_listener_2" {
  provider = aws.secondary
  load_balancer_arn = aws_lb.nlb_2.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.import_cert_2.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_2.arn
  }
  tags = {
    Name = "${var.api.name}-${var.region.secondary}-listener"
    region = var.region.secondary
  }
}
resource "aws_lb_listener_rule" "rule_2" {
  provider = aws.secondary
  listener_arn = aws_lb_listener.aws_lb_listener_2.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_2.arn
  }
  condition {
    path_pattern {
      values = ["/${var.api.name}/*"]
    }
  }
}
resource "aws_route53_record" "record_2" {
  provider = aws.secondary
  zone_id = aws_route53_zone.domain.zone_id
  name    = "api2.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.nlb_2.dns_name
    zone_id                = aws_lb.nlb_2.zone_id
    evaluate_target_health = false
  }
}
data "aws_vpc_endpoint_service" "service_2" {
  provider = aws.secondary
  service = "execute-api"
}

resource "aws_vpc_endpoint" "vpc_endpoint_2" {
  provider = aws.secondary
  vpc_id              = aws_vpc.vpc_2.id
  service_name        = data.aws_vpc_endpoint_service.service_2.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.api_subnet_2.id]
  security_group_ids = [aws_security_group.api_sg_2.id]
  tags = {
    name = "${var.api.name}-vpc-endpoint-${var.region.secondary}"
    region = var.region.secondary
  }
}
data "aws_network_interface" "nic_2" {
  provider = aws.secondary
  id = tolist(aws_vpc_endpoint.vpc_endpoint_2.network_interface_ids)[0]
}

##PEERING
resource "aws_vpc_peering_connection_accepter" "vpc_1_peer_accept" {
  provider                  = aws
  vpc_peering_connection_id = aws_vpc_peering_connection.inter_region_peering_1.id
  auto_accept               = true
  tags = {
    Name = "jumpbox-to-VPC1-Peer-Accept"
  }
}
resource "aws_vpc_peering_connection_accepter" "vpc_2_peer_accept" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.inter_region_peering_2.id
  auto_accept               = true
  tags = {
    Name = "jumpbox-to-VPC2-Peer-Accept"
  }
}
# Get the main route table for VPC1
data "aws_route_table" "vpc1_main" {
  provider = aws
  vpc_id   = aws_vpc.vpc_1.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}
# Add route to VPC2 in jumpbox's route table
resource "aws_route" "vpc1_to_jumpbox" {
  provider                = aws
  route_table_id          = data.aws_route_table.vpc1_main.id
  destination_cidr_block  = aws_vpc.jumpbox_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.inter_region_peering_1.id
}
# Get the main route table for VPC2
data "aws_route_table" "vpc2_main" {
  provider = aws.secondary
  vpc_id   = aws_vpc.vpc_2.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}
# Add route to VPC1 in VPC2's route table
resource "aws_route" "vpc2_to_jumpbox" {
  provider                = aws.secondary
  route_table_id          = data.aws_route_table.vpc2_main.id
  destination_cidr_block  = aws_vpc.jumpbox_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.inter_region_peering_2.id
}