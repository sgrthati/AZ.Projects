variable "location" {}
variable "subscription_id" {
  type = string
}

variable "tags" {
    type = map
}
variable "apimName" {
    type = string
}
variable "rgName" {
    type = string
}
variable "product" {
    type = map
}
variable "subscription" {
    type = map
}
variable "user" {
    type = map
}