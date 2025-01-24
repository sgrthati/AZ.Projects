#primary region vpc module
resource "aws_vpc" "jumpbox_vpc" {
  provider = aws
  cidr_block = var.vpc.jumpbox.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "jumpbox-${var.region.primary}"
  }
}
resource "aws_subnet" "jumpbox_subnet" {
  provider = aws
  vpc_id            = aws_vpc.jumpbox_vpc.id
  cidr_block        = var.vpc.jumpbox.jumpbox_subnet
  availability_zone = data.aws_availability_zones.available_1.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "jumpbox-subnet"
  }
}
resource "aws_internet_gateway" "igw" {
  provider = aws
  vpc_id = aws_vpc.jumpbox_vpc.id
  tags = {
    Name = "${aws_vpc.jumpbox_vpc.tags.Name}-${aws_subnet.jumpbox_subnet.tags.Name}-igw"
  }
} 
resource "aws_route_table" "public_rt" {
  provider = aws
  vpc_id = aws_vpc.jumpbox_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block = var.vpc.primary.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.inter_region_peering_1.id
  }
  route {
    cidr_block = var.vpc.secondary.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.inter_region_peering_2.id
  }
  tags = {
    Name = "${aws_vpc.vpc_1.tags.Name}-public-rt"
  }
}
resource "aws_route_table_association" "public_1_rt" {
  provider = aws
  subnet_id      = aws_subnet.jumpbox_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_security_group" "jumpbox_sg" {
  provider = aws
  vpc_id = aws_vpc.jumpbox_vpc.id
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
    region = var.region.primary
    "Security group name" = "jumpbox-sg"
  }
}
##PEERING
resource "aws_vpc_peering_connection" "inter_region_peering_1" {
  provider      = aws
  vpc_id        = aws_vpc.jumpbox_vpc.id
  peer_vpc_id   = aws_vpc.vpc_1.id
  tags = {
    Name = "Jumpbox-to-VPC1-InterRegion"
  }
}
resource "aws_vpc_peering_connection" "inter_region_peering_2" {
  provider      = aws
  vpc_id        = aws_vpc.jumpbox_vpc.id
  peer_vpc_id   = aws_vpc.vpc_2.id
  peer_region = var.region.secondary
  tags = {
    Name = "Jumpbox-to-VPC2-InterRegion"
  }
}
# EC2 instance in Public Subnet
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}
resource "aws_key_pair" "key" {
  provider = aws
  key_name = "key"
  public_key = file(var.public_key)
  tags = {
    name = "jumpbox-key"
    region = var.region.primary
  }
}
resource "aws_instance" "jumpbox" {
  provider = aws
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.jumpbox_subnet.id
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]
  key_name = aws_key_pair.key.key_name
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              cat <<CERT > /usr/local/share/ca-certificates/custom-cert.crt 
              ${tls_self_signed_cert.cert.cert_pem}
              CERT
              update-ca-certificates
              EOF
  tags = {
    Name = "jumpbox"
    region = var.region.primary
  }
}
