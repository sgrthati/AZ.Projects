variable "VM_name" {
  type = string
  default = ""
}
variable "RG_name" {
  type = string
  default = ""

}
variable "location" {
  type = string
  default = ""
}
variable "NIC" {
  default = ""
}

variable "admin_username" {
    type = string
    default = ""
}

variable "admin_password" {
    type = string
    default = ""
}