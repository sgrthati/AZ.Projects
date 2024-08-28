variable "resource_group_name" {
  type        = string
  description = "resource group name"
  default = "sri" #existing resource group name
}
variable "user_principal_name" {
  default = "admin@srisri.shop"
}
variable "tags" {
  type        = map
  description = "tags"
  default = {
    "env" = "dev"
  }
}