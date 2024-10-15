# data "azuread_client_config" "current" {}

# resource "azuread_application" "dev_application" {
#   display_name = "${local.apimName}-SP-DEV"
#   web {
#     redirect_uris = ["${azurerm_api_management.apim.developer_portal_url}/"]
#   }
# }

# resource "azuread_application_password" "dev_password" {
#   application_id = azuread_application.dev_application.id
# }

# resource "azurerm_api_management_identity_provider_aad" "identity_provider_aad" {
#   resource_group_name = azurerm_api_management.apim.resource_group_name
#   api_management_name = azurerm_api_management.apim.name
#   client_id           = azuread_application.dev_application.client_id
#   client_secret       = azuread_application_password.dev_password.value
#   allowed_tenants     = [data.azuread_client_config.current.tenant_id]
#   client_library = "MSAL"
# }