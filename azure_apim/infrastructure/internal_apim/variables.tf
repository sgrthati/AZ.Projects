variable "location" {}
variable "subscription_id" {
  type = string
}

variable "tags" {
    type = map
}
variable "backend" {
    type = map
}
variable "apim" {
  type = map
}

variable "prefix" {
    type = string
    default = "tc"
}
variable "virtualnetwork" {
  type = map
}

variable "resourceFunction" {
    type = string
}

variable "environment" {
    type = string
}

variable "storageAccountSku" {
    default = {
        tier = "Standard"
        type = "GRS"
    }
}

variable "apimSku" {
    type = string
}


variable "apimSkuCapacity" {
    type = number
}

variable "apimPublisherName" {
    type = string
}

variable "apimPublisherEmail" {
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
#REF:https://learn.microsoft.com/en-gb/azure/api-management/api-management-using-with-internal-vnet?tabs=stv2
variable "backend_rules" {
  type = map(object({
    priority    = number
    direction   = string
    access      = string
    protocol    = string
    source_port_range   = string
    destination_port_range  = string
    source_address_prefix   = string
    destination_address_prefix  = string
  }))
  default = {
    "In1" = {
      priority    = 100
      direction   = "Inbound"
      access      = "Allow"
      protocol    = "Tcp"
      source_port_range   = "*"
      destination_port_range  = "3443"
      source_address_prefix   = "ApiManagement"
      destination_address_prefix  = "VirtualNetwork"
    }
    In2 = {
      priority    = 200
      direction   = "Inbound"
      access      = "Allow"
      protocol    = "Tcp"
      source_port_range   = "*"
      destination_port_range  = "6390"
      source_address_prefix   = "AzureLoadBalancer"
      destination_address_prefix  = "VirtualNetwork"
    }
    #External Only
    # In3 = {
    #   priority    = 300
    #   direction   = "Inbound"
    #   access      = "Allow"
    #   protocol    = "Tcp"
    #   source_port_range   = "*"
    #   destination_port_range  = "443"
    #   source_address_prefix   = "AzureTrafficManager"
    #   destination_address_prefix  = "VirtualNetwork"
    # }
    Out1 = {
      priority    = 100
      direction   = "Outbound"
      access      = "Allow"
      protocol    = "Tcp"
      source_port_range   = "*"
      destination_port_range  = "443"
      source_address_prefix   = "VirtualNetwork"
      destination_address_prefix  = "Storage"
    }
    Out2 = {
      priority    = 200
      direction   = "Outbound"
      access      = "Allow"
      protocol    = "Tcp"
      source_port_range   = "*"
      destination_port_range  = "1433"
      source_address_prefix   = "VirtualNetwork"
      destination_address_prefix  = "SQL"
    }
    Out3 = {
      priority    = 300
      direction   = "Outbound"
      access      = "Allow"
      protocol    = "Tcp"
      source_port_range   = "*"
      destination_port_range  = "443"
      source_address_prefix   = "VirtualNetwork"
      destination_address_prefix  = "AzureKeyVault"
    }
    Out4 = {
      priority    = 400
      direction   = "Outbound"
      access      = "Allow"
      protocol    = "Tcp"
      source_port_range   = "*"
      destination_port_range  = "1886"
      source_address_prefix   = "VirtualNetwork"
      destination_address_prefix  = "AzureMonitor"
    }
    Out5 = {
      priority    = 500
      direction   = "Outbound"
      access      = "Allow"
      protocol    = "Tcp"
      source_port_range   = "*"
      destination_port_range  = "443"
      source_address_prefix   = "VirtualNetwork"
      destination_address_prefix  = "AzureMonitor"
    }
  }
}