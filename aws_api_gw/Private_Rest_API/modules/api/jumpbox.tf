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
resource "aws_instance" "jumpbox" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.jumpbox_subnet.id
  vpc_security_group_ids = [aws_security_group.jumpbox_sg.id]
  key_name = aws_key_pair.key.key_name
  tags = {
    Name = "jumpbox"
  }
}
