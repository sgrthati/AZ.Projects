# # Get data reference to logged Azure subcription
#REF:https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-ip-addresses#ip-addresses-of-api-management-service-in-vnet
#REF:https://learn.microsoft.com/en-us/azure/api-management/virtual-network-concepts
#REF:https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet?tabs=stv2
data "azurerm_client_config" "data" {}

# Create a new resource group
resource "azurerm_resource_group" "rg" {
  name     = local.resourceGroupName
  location = var.location
  tags     = var.tags
}
#Create a new APIM instance
resource "azurerm_api_management" "apim" {
  name                = local.apimName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.apimPublisherName
  publisher_email     = var.apimPublisherEmail
  tags                = var.tags
  # public_network_access_enabled = false #for internal APIM
  delegation {
    user_registration_enabled = true
    subscriptions_enabled     = true
  }
  # virtual_network_type = "None"
  # virtual_network_configuration {
  #   subnet_id = azurerm_subnet.gatewaySubnet.id
  # }
  sku_name            = "${var.apimSku}_${var.apimSkuCapacity}"
  identity {
    type = "SystemAssigned"
  }
  protocols {
    enable_http2 = true
  }
  security {
    enable_backend_ssl30                                = false
    enable_backend_tls10                                = false
    enable_backend_tls11                                = false
    enable_frontend_ssl30                               = false
    enable_frontend_tls10                               = false
    enable_frontend_tls11                               = false
    tls_ecdhe_ecdsa_with_aes128_cbc_sha_ciphers_enabled = false
    tls_ecdhe_ecdsa_with_aes256_cbc_sha_ciphers_enabled = false
    tls_ecdhe_rsa_with_aes128_cbc_sha_ciphers_enabled   = false
    tls_ecdhe_rsa_with_aes256_cbc_sha_ciphers_enabled   = false
    tls_rsa_with_aes128_cbc_sha256_ciphers_enabled      = false
    tls_rsa_with_aes128_cbc_sha_ciphers_enabled         = false
    tls_rsa_with_aes128_gcm_sha256_ciphers_enabled      = false
    tls_rsa_with_aes256_cbc_sha256_ciphers_enabled      = false
    tls_rsa_with_aes256_cbc_sha_ciphers_enabled         = false
    tls_rsa_with_aes256_gcm_sha384_ciphers_enabled      = false
    triple_des_ciphers_enabled                          = false
  }
  sign_in {
    enabled = true
  }
  sign_up {
    enabled = true
    terms_of_service {
      text = "Terms of service"
      consent_required = true
      enabled          = true
    }
  }
}


resource "azurerm_private_endpoint" "pe" {
  name                = "${local.apimName}-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.gatewaySubnet.id
  tags                = var.tags
  depends_on = [azurerm_api_management.apim]
  private_service_connection {
    name                           = "${local.apimName}-pe-connection"
    private_connection_resource_id = azurerm_api_management.apim.id
    subresource_names              = ["Gateway"]
    is_manual_connection           = false
  }
}

#disable public network access in apim
resource "azapi_update_resource" "disable_public_network_access" {
  type = "Microsoft.ApiManagement/service@2021-08-01"
  name = azurerm_api_management.apim.name
  body = jsonencode({
    properties = {
      publicNetworkAccess = "Disabled"
    }
  }) 
}