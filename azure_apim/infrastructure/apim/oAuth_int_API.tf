# resource "azuread_application" "api_application" {
#   display_name = "${local.apimName}-SP-API"
#   web {
#     redirect_uris = ["${azurerm_api_management.apim.gateway_url}/"]
#   }
#   required_resource_access {
#     resource_app_id = "00000003-0000-0000-c000-000000000000"
#     # Note: Role permissions display as Application and scope permissions display as Delegated in the Azure portal
#     resource_access {
#       id   = "bdfbf15f-ee85-4955-8675-146e8e5296b5" //AAD Application.ReadWrite.All
#       type = "Scope"
#     }
#     resource_access {
#       id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" //AAD User.Read
#       type = "Scope"
#     }
#   }
# }

# resource "azuread_application_password" "api_password" {
#   application_id = azuread_application.dev_application.id
# }
# resource "azurerm_api_management_authorization_server" "apim_auth" {

#   name                         = "${local.apimName}-auth"
#   api_management_name          = azurerm_api_management.apim.name
#   resource_group_name          = azurerm_api_management.apim.resource_group_name
#   display_name                 = azurerm_api_management.apim.name
#   authorization_endpoint       = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/authorize"
#   client_id                    = azuread_application.api_application.client_id
#   client_secret                = azuread_application_password.api_password.value
#   client_registration_endpoint = "http://localhost"
#   token_endpoint               = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/token"

#   client_authentication_method = [
#     "Body"
#   ]

#   authorization_methods = [
#     "GET"
#   ]

#   bearer_token_sending_methods = [
#     "authorizationHeader"
#   ]

#   grant_types = [
#     "authorizationCode"
#   ]
# }