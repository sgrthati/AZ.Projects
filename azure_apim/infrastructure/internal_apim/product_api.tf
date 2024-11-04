# # here we are going to create a API Product along with API,Subscription,Group,User
# # Create Product for APIM management
# resource "azurerm_api_management_product" "product" {
#   product_id            = var.product.productId
#   api_management_name   = azurerm_api_management.apim.name
#   resource_group_name   = azurerm_resource_group.rg.name
#   display_name          = var.product.productName
#   subscription_required = var.product.subscriptionRequired
#   subscriptions_limit   = var.product.subscriptionsLimit
#   approval_required     = var.product.approvalRequired
#   published             = var.product.published
# }
# #to create API management Group
# resource "azurerm_api_management_group" "group" {
#   name                = "${var.product.productId}-group"
#   resource_group_name = azurerm_resource_group.rg.name
#   api_management_name = azurerm_api_management.apim.name
#   display_name        = "${var.product.productId}-group"
#   description         = "${var.product.productId}-group"
# }
# #mapping product to a group
# resource "azurerm_api_management_product_group" "example" {
#   product_id          = azurerm_api_management_product.product.product_id
#   group_name          = azurerm_api_management_group.group.name
#   api_management_name = azurerm_api_management.apim.name
#   resource_group_name = azurerm_resource_group.rg.name
# }

# # Create Users - not available for Consumption plan
# resource "azurerm_api_management_user" "user" {
#   user_id             = "${var.product.productId}-user"
#   api_management_name = azurerm_api_management.apim.name
#   resource_group_name = azurerm_resource_group.rg.name
#   first_name          = var.user.firstName
#   last_name           = var.product.productName
#   email               = var.user.email
#   state               = "active"
#   confirmation        = "invite"
#   password = var.user.password

#   depends_on = [azurerm_api_management_product.product]
# }

# resource "azurerm_api_management_group_user" "gp_user_mapping" {
#   user_id             = "${var.product.productId}-user"
#   group_name          = "${var.product.productId}-group"
#   resource_group_name = azurerm_resource_group.rg.name
#   api_management_name = azurerm_api_management.apim.name
#   depends_on = [ azurerm_api_management_product.product, azurerm_api_management_user.user ]
# }

# # Create subscription
# resource "azurerm_api_management_subscription" "subscription" {
#   api_management_name = azurerm_api_management.apim.name
#   resource_group_name = azurerm_resource_group.rg.name
#   product_id          = azurerm_api_management_product.product.id
#   display_name        = var.subscription.subscriptionName
#   state               = "active"

#   depends_on = [
#       azurerm_api_management_product.product,
#       azurerm_api_management_user.user
#   ]
# }
# #to create Sample API
# resource "azurerm_api_management_api" "api" {
#   name                = "example-api"
#   resource_group_name = azurerm_resource_group.rg.name
#   api_management_name = azurerm_api_management.apim.name
#   revision            = "1"
#   display_name        = "Example API"
#   path                = "srisri"
#   protocols           = ["http","https"]

#   import {
#     content_format = "openapi"
#     content_value  = file("./openAPI/openAPI.yaml")
#   }
# }
# #to create API under product
# resource "azurerm_api_management_product_api" "product_api" {
#   api_name            = azurerm_api_management_api.api.name
#   product_id          = azurerm_api_management_product.product.product_id
#   api_management_name = azurerm_api_management.apim.name
#   resource_group_name = azurerm_resource_group.rg.name
# }
# #adding backed manually
# resource "azurerm_api_management_api_policy" "api_policy" {
#   api_name            = azurerm_api_management_api.api.name
#   api_management_name = azurerm_api_management.apim.name
#   resource_group_name = azurerm_resource_group.rg.name
#   xml_content         = file("./openAPI/policy.xml")
# }
# #backend
# resource "azurerm_api_management_backend" "backend" {
#   name                = "example-backend"
#   resource_group_name = azurerm_resource_group.rg.name
#   api_management_name = azurerm_api_management.apim.name
#   protocol            = "http"
#   url                 = "https://jsonplaceholder.typicode.com"
# }
# # # to create API operation
# # resource "azurerm_api_management_api_operation" "get_sessions" {
# #   api_name            = azurerm_api_management_api.api.name
# #   api_management_name = azurerm_api_management.apim.name
# #   resource_group_name = azurerm_resource_group.rg.name
# #   operation_id       = "getSessions"
# #   display_name       = "Get Sessions"
# #   method             = "GET"
# #   url_template       = "/get" // Adjust based on your backend
# #   response {
# #     status_code = 200
# #     description = "Successful response"
# #   }
# # }
# # # to create API operation policy
# # resource "azurerm_api_management_api_operation_policy" "set-backend" {
# #   api_name = azurerm_api_management_api.api.name
# #   operation_id        = azurerm_api_management_api_operation.get_sessions.operation_id
# #   api_management_name = azurerm_api_management.apim.name
# #   resource_group_name = azurerm_resource_group.rg.name
# #    xml_content = <<XML
# # <policies>
# #   <inbound>
# #      <set-backend-service backend-id="${azurerm_api_management_backend.backend.url}" />
# #   </inbound>
# # </policies>
# # XML
# # }