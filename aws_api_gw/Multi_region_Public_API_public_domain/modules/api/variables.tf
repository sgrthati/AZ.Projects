variable "api" {
    type = map
}
variable "region" {
  type = object({
    primary   = string
    secondary = string
  })
}
variable "domain_name" {
  type = string  
}
variable "zone_id" {
  type = string
}