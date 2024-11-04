# # Create Application Insights
# resource "azurerm_application_insights" "ai" {
#   name                = local.appInsightsName
#   location            = var.location
#   resource_group_name = azurerm_resource_group.rg.name
#   application_type    = "web"
#   tags                = var.tags
# }

# # Create Logger
# resource "azurerm_api_management_logger" "apimLogger" {
#   name                = "${local.apimName}-logger"
#   api_management_name = azurerm_api_management.apim.name
#   resource_group_name = azurerm_resource_group.rg.name

#   application_insights {
#     instrumentation_key = azurerm_application_insights.ai.instrumentation_key
#   }
# }
# #to pull service API Daignostic Logs
# #https://learn.microsoft.com/en-us/azure/api-management/diagnostic-logs-reference
# resource "azurerm_api_management_diagnostic" "api_diagnostic" {
#   identifier               = "applicationinsights"
#   resource_group_name      = azurerm_resource_group.rg.name
#   api_management_name      = azurerm_api_management.apim.name
#   api_management_logger_id = azurerm_api_management_logger.apimLogger.id

#   sampling_percentage       = 100.0
#   always_log_errors         = true
#   log_client_ip             = true
#   verbosity                 = "verbose"
#   http_correlation_protocol = "W3C"

#   frontend_request {
#     body_bytes = 32
#     headers_to_log = [
#       "content-type",
#       "accept",
#       "origin",
#     ]
#   }

#   frontend_response {
#     body_bytes = 32
#     headers_to_log = [
#       "content-type",
#       "content-length",
#       "origin",
#     ]
#   }

#   backend_request {
#     body_bytes = 32
#     headers_to_log = [
#       "content-type",
#       "accept",
#       "origin",
#     ]
#   }

#   backend_response {
#     body_bytes = 32
#     headers_to_log = [
#       "content-type",
#       "content-length",
#       "origin",
#     ]
#   }
# }