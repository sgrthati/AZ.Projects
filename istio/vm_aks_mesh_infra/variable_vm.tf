variable "allowed_inbound_ports" {
  type = map(object({
    port     = string
    priority = number
  }))
  default = {
    "AllowSSH" = {
      port     = "22"
      priority = 100
    }
    "AllowAPP" = {
      port     = "5000"
      priority = 110
    }
  }
}