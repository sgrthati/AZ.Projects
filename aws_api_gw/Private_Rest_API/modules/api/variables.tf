variable "api" {
    type = map
}
variable "region" {
  type = string
}
variable "vpc" {
  type = map
}
variable "os" {
    default = "ami-08a52ddb321b32a8c"
}
variable "instance" {
    default = "t2.micro"
}
variable "public_key" {
    default = "~/.ssh/id_rsa.pub"
}