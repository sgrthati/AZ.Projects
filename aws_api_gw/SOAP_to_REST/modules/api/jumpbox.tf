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
  key_name = "key"
  public_key = file(var.public_key)
  tags = {
    name = "jumpbox-key"
  }
}
data "local_file" "script" {
  filename = "./supporting_files/API.sh"
}
data "aws_vpc" "vpc" {
  default = true
}
data "aws_subnet" "subnet" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "availability-zone"
    values = ["${var.region}a"]
  }
}
resource "aws_security_group" "sg" {
  name = "security group from terraform"
  vpc_id = data.aws_vpc.vpc.id
  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from the internet on 5000"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "80 from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_instance" "jumpbox" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              cat <<APP > /api.sh
              ${data.local_file.script.content}
              APP
              ./api.sh
              EOF
  key_name = aws_key_pair.key.key_name
  tags = {
    Name = "jumpbox"
  }
}
