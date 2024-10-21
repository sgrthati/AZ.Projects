data "azuread_client_config" "current" {}

resource "azuread_application" "dev_application" {
  display_name        = "${local.apimName}-SP-DEV"
  sign_in_audience    = "AzureADandPersonalMicrosoftAccount"
  owners              = [data.azuread_client_config.current.object_id]

  web {
    redirect_uris = ["https://${local.apimName}.developer.azure-api.net/signin-oauth/code/callback/oauth-authorizationcodeflow",
    "https://${local.apimName}.developer.azure-api.net/signin-oauth/implicit/callback",
    "https://${local.apimName}.developer.azure-api.net/signin-oauth/code/callback/test-apim-dev-apim-auth"]
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
  api {
    requested_access_token_version = 2
  }
  required_resource_access {
    resource_app_id = azuread_application.api_application.client_id
    resource_access {
        id = random_uuid.test.result
        type = "Scope"
    }
  }
}
# admin consent
resource "null_resource" "admin_consent" {
  depends_on = [azuread_application.dev_application]

  provisioner "local-exec" {
    command = "az ad app permission admin-consent --id ${azuread_application.dev_application.client_id}"
  }
}

resource "azuread_application_password" "dev_password" {
  application_id = azuread_application.dev_application.id
}

# resource "azurerm_api_management_identity_provider_aad" "identity_provider_aad" {
#   resource_group_name = azurerm_api_management.apim.resource_group_name
#   api_management_name = azurerm_api_management.apim.name
#   client_id           = azuread_application.dev_application.client_id
#   client_secret       = azuread_application_password.dev_password.value
#   allowed_tenants     = [data.azuread_client_config.current.tenant_id]
#   signin_tenant       = data.azuread_client_config.current.tenant_id
#   client_library      = "ADAL"
# }