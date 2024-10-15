#!/bin/bash
set -euxo pipefail
WORKDIR="/mnt/d/cluster/AZ.Projects/azure_apim/infrastructure/"
# Set Azure APIM variables
PRODUCT_NAME="srisri"
API_NAME="api1"
USER_EMAIL="sagarpranith@outlook.in"
SPECIFICATION_PATH="$WORKDIR/openAPI/openAPI.yaml"
RESOURCE_GROUP=$(terraform output -state "$WORKDIR/apim/terraform.tfstate" -raw apim_rg_name)
APIM_NAME=$(terraform output -state "$WORKDIR/apim/terraform.tfstate" -raw apim_name)
cd $WORKDIR
# Import the API into the product
az apim api import \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --path "$API_NAME" \
    --api-id "$PRODUCT_NAME-$API_NAME" \
    --specification-format "OpenApi" \
    --specification-path "$SPECIFICATION_PATH" \
    --protocols "https"

# Create a group if it doesn't already exist
az apim group create \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --group-id "$PRODUCT_NAME-group" \
    --display-name "$PRODUCT_NAME-group" \
    --description "Description of the group"

# Create a user
az apim user create \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --email "$USER_EMAIL" \
    --firstname "$PRODUCT_NAME" \
    --lastname "ADMIN" \
    --state "active"
# Add user to group
az apim group user add \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --group-id "$PRODUCT_NAME-group" \
    --user-id "$USER_EMAIL"

# Assign product to group
az apim product group add \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --product-id "$PRODUCT_NAME" \
    --group-id "$PRODUCT_NAME-group"

# Create a subscription for the user
az apim subscription create \
    --resource-group "$RESOURCE_GROUP" \
    --service-name "$APIM_NAME" \
    --product-id "$PRODUCT_NAME" \
    --subscriber-id "$USER_EMAIL" \
    --display-name "$PRODUCT_NAME-SUBSCRIPTION" \
    --state "active"
