variable "api" {
    type = map
}
variable "region" {
  type = object({
    primary   = string
    secondary = string
  })
}
variable "primary_vpc_id" {
  type = string
}
variable "secondary_vpc_id" {
  type = string
}
variable "os" {
    default = "ami-08a52ddb321b32a8c"
}
variable "instance" {
    default = "t2.micro"
}
variable "primary_api_subnet_id" {
  type = string
}
variable "primary_api_sg_id" {
  type = string  
}
variable "secondary_api_subnet_id" {
  type = string
}
variable "secondary_api_sg_id" {
  type = string  
}
variable "primary_lb_arn" {
  type = string
}
variable "secondary_lb_arn" {
  type = string  
}
variable "domain_name" {
  type = string  
}

variable "primary_lb_tg_arn" {
  type = string 
}
variable "secondary_lb_tg_arn" {
  type = string 
}
variable "primary_vpc_endpoint_ip" {
  type = string
}
variable "secondary_vpc_endpoint_ip" {
  type = string  
}
variable "primary_vpc_endpoint_id" {
  type = string
}
variable "secondary_vpc_endpoint_id" {
  type = string  
}