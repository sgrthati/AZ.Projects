#creating backend,it is going to be used in apim
# resource "azurerm_public_ip" "pip1" {
#     name = "${local.apimName}-backend1-pip"
#     location = azurerm_resource_group.rg.location
#     resource_group_name = azurerm_resource_group.rg.name
#     allocation_method = "Static"
#     sku = "Standard"
#     tags = var.tags
# }
resource "azurerm_network_interface" "nic" {
    name                = "${local.apimName}-backend1-nic"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name            = "internal"
        subnet_id       = azurerm_subnet.backendSubnet.id
        private_ip_address_allocation = "Dynamic"
        # public_ip_address_id = try(azurerm_public_ip.pip1.id, null)
    }
}
resource "azurerm_linux_virtual_machine" "backend1" {
    name                  = "${local.apimName}-backend1"
    computer_name         = "${local.apimName}-backend1"
    resource_group_name   = azurerm_resource_group.rg.name
    location              = azurerm_resource_group.rg.location
    size                  = "Standard_B2s"
    admin_username        = var.backend.username
    admin_password        = var.backend.password
    network_interface_ids = [azurerm_network_interface.nic.id]
    disable_password_authentication = false
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    custom_data = filebase64("./scripts/API.sh")
    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
}

