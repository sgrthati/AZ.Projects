#!/bin/bash
#import Complete API into APIM using API
set -euxo pipefail
# Variables (replace with your actual values)
TENANT_ID="$(az account show --query tenantId --output tsv)"
CLIENT_ID="<CLIENT_ID>"
CLIENT_SECRET="<CLIENT_SECRET>"
SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
RESOURCE_GROUP="test-apim-dev-rg"
APIM_NAME="test-apim-dev-apim"
# API details (replace with actual values)
API_ID="REST-API"   # Unique ID for the API
DISPLAY_NAME="REST API"
AUTH_SERVER="test-apim-dev-apim-auth"
# User details
USER_ID="TEST"
FIRST_NAME="TEST"
LAST_NAME="REST"
EMAIL="test@srisri.xyz"
PASSWORD="Azure@2024"


# Get Azure AD token
ACCESS_TOKEN=$(curl -X POST -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=${CLIENT_ID}&scope=https%3A%2F%2Fmanagement.azure.com%2F.default&client_secret=${CLIENT_SECRET}&grant_type=client_credentials" \
  https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token | jq -r .access_token)


# Import OpenAPI spec
curl -i -X PUT "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/apis/${API_ID}?import=true&api-version=2023-09-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
  "properties": {
    "format": "openapi-link",
    "value": "https://raw.githubusercontent.com/sgrthati/AZ.Projects/refs/heads/main/azure_apim/infrastructure/openAPI/openAPI.yaml",
    "path": "openAPI"
   }
  }
}'

  # Create Product
curl -X PUT "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/products/${API_ID}-PRODUCT?api-version=2023-09-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "properties": {
      "displayName": "'"${API_ID}-PRODUCT"'",
      "description": "An example product",
      "subscriptionRequired": true,
      "approvalRequired": false,
      "state": "published"
    }
  }'
# Associate the API with the Product
curl -X PUT "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/products/${API_ID}-PRODUCT/apis/${API_ID}?api-version=2023-09-01-preview" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d '{}'

# Create User
curl -X PUT "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/users/${USER_ID}?api-version=2023-09-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "properties": {
      "firstName": "'"${FIRST_NAME}"'",
      "lastName": "'"${LAST_NAME}"'",
      "email": "'"${EMAIL}"'",
      "confirmation": "signup",
      "password": "'"${PASSWORD}"'",
      "state": "active",
      "groups": ["'"${API_ID}-GROUP"'"],
    }
  }'

# Create Group
curl -X PUT "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/groups/${API_ID}-GROUP?api-version=2023-09-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "properties": {
      "displayName": "'"${API_ID}-GROUP"'",
    }
  }'

# Add User to Group
curl -X PUT "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/groups/${API_ID}-GROUP/users/${USER_ID}?api-version=2023-09-01-preview" \
-H "Authorization: Bearer ${ACCESS_TOKEN}" \
-H "Content-Type: application/json" \
-d '{}'

#add product to group
curl -X PUT "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/products/${API_ID}-PRODUCT/groups/${API_ID}-GROUP?api-version=2023-03-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-length: 0" \
  -H "Content-Type: application/json"

# Create Subscription
curl -X PUT "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/subscriptions/${API_ID}-SUBSCRIPTION?api-version=2023-09-01-preview" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "properties": {
      "scope": "/products/'"${API_ID}-PRODUCT"'",
      "displayName": "'"${API_ID}-SUBSCRIPTION"'",
      "userId": "/users/'"${USER_ID}"'"
    }
  }'
