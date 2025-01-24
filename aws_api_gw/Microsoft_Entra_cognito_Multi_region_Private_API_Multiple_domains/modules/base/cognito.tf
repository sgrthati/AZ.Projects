##################################
##   AZURE AD ##
##################################
data "azuread_client_config" "current" {}
data "azuread_application_published_app_ids" "well_known" {}
data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
}
data "azuread_service_principals" "all" {
  return_all = true
}
resource "azuread_application" "app" {
  display_name = "aws-apigw-cognito"
  owners = [data.azuread_client_config.current.object_id]
  identifier_uris = [aws_cognito_user_pool.pool_1.arn]
  web {
    redirect_uris = [ "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.region.primary}.amazoncognito.com/saml2/idpresponse" ]
  }
  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
    resource_access {
      id   = data.azuread_service_principal.msgraph.app_role_ids["User.Read.All"]
      type = "Role"
    }
    resource_access {
      id   = data.azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.ReadWrite"]
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "sp" {
  client_id = azuread_application.app.client_id
  app_role_assignment_required = true
  owners = [data.azuread_client_config.current.object_id]
  feature_tags {
    enterprise = true
  }
}
resource "azuread_group" "owner" {
  display_name     = "aws-apigw-cognito-owners"
  security_enabled = true
  owners           = [data.azuread_client_config.current.object_id]
}
resource "azuread_user" "user" {
  user_principal_name = "apigwtest@srisri.xyz"
  display_name        = "apigwtest"
  mail_nickname       = "apigwtest"
  password            = "Cloud@20252025"
}
resource "azuread_group_member" "add_user_group" {
  group_object_id  = azuread_group.owner.object_id
  member_object_id = azuread_user.user.object_id
}
resource "azuread_app_role_assignment" "api_permissions" {
  for_each = { for v in flatten([
    for rra in azuread_application.app.required_resource_access : [
      for ra in rra.resource_access : {
        resource_object_id = one([
          # Loop through all the service principals and find the object_id of the one
          # that matches the client_id of the resource_app_id from the azuread_application.
          for sp in data.azuread_service_principals.all.service_principals :
          sp.object_id
          if sp.client_id == rra.resource_app_id
        ])
        app_role_id = ra.id
      }
      if ra.type == "Role"
    ]
  ]) : join("|", [v.resource_object_id, v.app_role_id]) => v }

  principal_object_id = azuread_service_principal.sp.object_id
  resource_object_id  = each.value.resource_object_id
  app_role_id         = each.value.app_role_id
}
##################################
##   PRIMARY REGION ##
##################################
resource "aws_cognito_user_pool" "pool_1" {
  provider = aws
  name = "apigw-${var.region.primary}"
}
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "apigw-${var.region.primary}"
  user_pool_id = aws_cognito_user_pool.pool_1.id
}
resource "aws_cognito_user_pool_client" "pool_client_1" {
  provider = aws
  name                                 = "apigw-${var.region.primary}-pool-client"
  generate_secret = true
  user_pool_id                         = aws_cognito_user_pool.pool_1.id
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["aws.cognito.signin.user.admin"]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]
  callback_urls                        = ["https://example.com"]
  prevent_user_existence_errors        = "ENABLED"
}
resource "aws_cognito_user" "yt_user" {
  user_pool_id = aws_cognito_user_pool.pool_1.id
  username     = var.cognito.user1
  password     = var.cognito.password
}