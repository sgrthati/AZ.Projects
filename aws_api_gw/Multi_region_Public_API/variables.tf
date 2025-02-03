variable "region" {
  type = object({
    primary   = string
    secondary = string
  })
}
variable "api" {
  type = map
}
variable "vpc" {
  type = map
}
variable "domain_name" {
  type = string  
}