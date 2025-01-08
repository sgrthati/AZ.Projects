resource "aws_vpc" "vpc" {
  cidr_block = var.vpc.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "api-vpc"
  }
}
data "aws_availability_zones" "available" {}
resource "aws_subnet" "api_subnet" {
    vpc_id            = aws_vpc.vpc.id
    cidr_block        = var.vpc.api_subnet
    availability_zone = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = false
    tags = {
      Name = "api-subnet"
    }
}
resource "aws_subnet" "jumpbox_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.vpc.jumpbox_subnet
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "jumpbox-subnet"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw for JumpBox"
  }
} 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "route table for public subnet"
  }
}
resource "aws_route_table_association" "public_1_rt" {
  subnet_id      = aws_subnet.jumpbox_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_security_group" "jumpbox_sg" {
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "jumpbox-sg"
  }
}
resource "aws_security_group" "api_sg" {
  vpc_id = aws_vpc.vpc.id
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
  }
}
data "aws_vpc_endpoint_service" "service" {
  service = "execute-api"
}
resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = data.aws_vpc_endpoint_service.service.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [aws_subnet.api_subnet.id]
  security_group_ids = [aws_security_group.api_sg.id]
}