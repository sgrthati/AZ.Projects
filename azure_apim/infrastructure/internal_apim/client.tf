# #creating backend,it is going to be used in apim
# resource "azurerm_public_ip" "pip" {
#     name = "${local.apimName}-client-pip"
#     location = azurerm_resource_group.rg.location
#     resource_group_name = azurerm_resource_group.rg.name
#     allocation_method = "Static"
#     sku = "Standard"
#     tags = var.tags
# }
# resource "azurerm_network_interface" "nic_client" {
#     name                = "${local.apimName}-client-nic"
#     location            = azurerm_resource_group.rg.location
#     resource_group_name = azurerm_resource_group.rg.name
#     depends_on = [ azurerm_public_ip.pip ]
#     ip_configuration {
#         name            = "internal"
#         subnet_id       = azurerm_subnet.userSubnet.id
#         private_ip_address_allocation = "Dynamic"
#         public_ip_address_id = try(azurerm_public_ip.pip.id, null)
#     }
# }
# resource "azurerm_linux_virtual_machine" "client" {
#     name                  = "${local.apimName}-client"
#     computer_name         = "${local.apimName}-client"
#     resource_group_name   = azurerm_resource_group.rg.name
#     location              = azurerm_resource_group.rg.location
#     size                  = "Standard_B2s"
#     admin_username        = var.backend.username
#     admin_password        = var.backend.password
#     network_interface_ids = [azurerm_network_interface.nic_client.id]
#     disable_password_authentication = false
#     os_disk {
#         caching              = "ReadWrite"
#         storage_account_type = "Standard_LRS"
#     }
#     source_image_reference {
#         publisher = "Canonical"
#         offer     = "UbuntuServer"
#         sku       = "18.04-LTS"
#         version   = "latest"
#     }
# }

