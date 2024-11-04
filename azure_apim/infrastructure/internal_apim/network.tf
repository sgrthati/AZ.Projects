#Create a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.apimName}-vnet" 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.virtualnetwork.NetworkAddress]
  tags                = var.tags
}

resource "azurerm_subnet" "gatewaySubnet" {
  name                 = "${local.apimName}-gateway-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.virtualnetwork.gatewaySubnetAddress]
  private_link_service_network_policies_enabled = true 
}

resource "azurerm_subnet" "backendSubnet" {
  name                 = "${local.apimName}-backend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.virtualnetwork.backendSubnetAddress]
  private_link_service_network_policies_enabled = true 
}

resource "azurerm_subnet" "userSubnet" {
  name                 = "${local.apimName}-users-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.virtualnetwork.subnetAddress]
  private_link_service_network_policies_enabled = true 
}

resource "azurerm_network_security_group" "apim_nsg" {
  name                  = "${local.apimName}-NSG"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
}
resource "azurerm_network_security_rule" "apim_nsg_rule" {
    for_each                    = var.backend_rules
    name                        = "${each.key}-rule"
    priority                    = each.value.priority
    direction                   = each.value.direction
    access                      = each.value.access
    protocol                    = each.value.protocol
    source_port_range           = each.value.source_port_range
    destination_port_range      = each.value.destination_port_range
    source_address_prefix       = each.value.source_address_prefix
    destination_address_prefix  = each.value.destination_address_prefix
    resource_group_name         = azurerm_resource_group.rg.name
    network_security_group_name = azurerm_network_security_group.apim_nsg.name
}
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.gatewaySubnet.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}
