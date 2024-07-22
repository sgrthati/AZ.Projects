# script used for to ping multiple times
# script.sh <no.of pings>
# EX: ./script.sh 10
check_azure_login() {
    if ! az account show &> /dev/null; then
        echo "You are not logged in to Azure. Please log in."
        az login
    fi
}
# Function to fetch token using Azure AD
fetch_token_azure_ad() {
    RESOURCE="https://management.azure.com/"
    az account get-access-token --resource=$RESOURCE --query accessToken --output tsv
}
# Function to fetch token using Service Principal
fetch_token_service_principal() {
    #read the variables
    read -p "Please enter the TENANT_ID: " TENANT_ID
    read -p "Please enter the CLIENT_ID: " CLIENT_ID
    read -sp "Please enter the CLIENT_SECRET: " CLIENT_SECRET
    RESOURCE="https://management.azure.com/"
    # Get JWT Token
    curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&resource=$RESOURCE" https://login.microsoftonline.com/$TENANT_ID/oauth2/token | jq -r '.access_token'
}

# Prompt user to choose authentication method
echo "Choose authentication method:"
echo "1) Azure AD"
echo "2) Service Principal"
read -p "Enter choice [1 or 2]: " choice

case $choice in
    1)
        check_azure_login
        TOKEN=$(fetch_token_azure_ad)
        ;;
    2)
        TOKEN=$(fetch_token_service_principal)
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
# Number of requests to send
NUM_REQUESTS=$1
read -p "Please enter the INGRESS_IP: " istio_endpoint
# Loop to send multiple requests
for ((i = 1; i <= NUM_REQUESTS; i++)); do
    # Get response code
    response_code=$(curl -H "Authorization: Bearer $TOKEN" -o /dev/null -s -w "%{http_code}" ${istio_endpoint}/hello)
    # Get response content
    RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" ${istio_endpoint}/hello)
    # Print response number, content, and response code
    echo "Request $i: $RESPONSE : $response_code"
done
