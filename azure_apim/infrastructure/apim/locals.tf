locals {
  resourceGroupName  = "${var.resourceFunction}-${var.environment}-apim-rg"
  apimName          = "${var.resourceFunction}-${var.environment}-apim"
  appInsightsName    = "${var.resourceFunction}-${var.environment}-apim-ai"
}