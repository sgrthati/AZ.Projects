resource "random_uuid" "test" {}

resource "azuread_application" "api_application" {
  display_name          = "${local.apimName}-SP-API"
  sign_in_audience      = "AzureADandPersonalMicrosoftAccount"
  owners                = [data.azuread_client_config.current.object_id]

  api {
    requested_access_token_version = 2
    oauth2_permission_scope {
      id                         = random_uuid.test.result # Ensure this is a valid GUID format
      type                       = "User"
      admin_consent_display_name = "${local.apimName}-user-read"
      admin_consent_description  = "${local.apimName}-user-read permission for API"
      user_consent_display_name  = "${local.apimName}-read permission"
      user_consent_description   = "${local.apimName}-user-read"
      value                      = "user.read"
      enabled                    = true # Ensure the scope is enabled
    }
  }
}

resource "azuread_application_identifier_uri" "api_ad_uri" {
  application_id = azuread_application.api_application.id
  identifier_uri = "api://${azuread_application.api_application.client_id}"
  depends_on = [ azuread_application.api_application ]
}

resource "azuread_service_principal" "api_sp" {
  client_id = azuread_application.api_application.client_id
}
# # Add a time delay after the service principal creation
# resource "null_resource" "wait_for_sp" {
#   depends_on = [azuread_service_principal.api_sp]

#   provisioner "local-exec" {
#     command = "sleep 30"
#   }
# }
# resource "azuread_app_role_assignment" "api_role" {
#   app_role_id         = random_uuid.test.result
#   principal_object_id = azuread_service_principal.api_sp.object_id
#   resource_object_id  = azuread_application.api_application.object_id

#   # Add explicit dependency to ensure proper resource creation order
#   depends_on = [
#     azuread_service_principal.api_sp,
#     null_resource.wait_for_sp
#   ]
# }


resource "azuread_application_password" "api_password" {
  application_id = azuread_application.api_application.id
}
resource "azurerm_api_management_authorization_server" "apim_auth" {

  name                         = "${local.apimName}-auth"
  api_management_name          = azurerm_api_management.apim.name
  resource_group_name          = azurerm_api_management.apim.resource_group_name
  display_name                 = azurerm_api_management.apim.name
  authorization_endpoint       = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/authorize"
  client_id                    = azuread_application.dev_application.client_id
  client_secret                = azuread_application_password.dev_password.value
  client_registration_endpoint = "http://localhost"
  token_endpoint               = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/v2.0/token"
  default_scope = "api://${azuread_application.api_application.client_id}/user.read"

  client_authentication_method = [
    "Body"
  ]

  authorization_methods = [
    "GET",
    "POST"
  ]

  bearer_token_sending_methods = [
    "authorizationHeader"
  ]

  grant_types = [
    "authorizationCode"
  ]
}