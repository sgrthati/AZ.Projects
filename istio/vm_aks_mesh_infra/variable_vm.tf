variable "allowed_inbound_ports" {
  description = "Map of allowed inbound ports with priorities"
  type = map(object({
    port     = string
    priority = number
  }))
  default = {
    "AllowALL" = {
      port     = "*"
      priority = 100
  }
}
}