data "azurerm_api_management" "apim" {
    name                = var.apimName
    resource_group_name = var.rgName
}