variable "region" {
  type = object({
    primary   = string
    secondary = string
  })
}
variable "domain_name" {
  type = string
}
variable "api" {
  type = map  
}
variable "cognito" {
  type = map
}