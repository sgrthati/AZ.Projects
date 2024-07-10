# script used for to ping multiple times
# script.sh <no.of pings>
# EX: ./script.sh 10
#for fetch token with azure ad user:TOKEN=$(az account get-access-token --resource=https://management.azure.com/ --query accessToken --output tsv)
#read the variables
read -p "Please enter the TENANT_ID: " TENANT_ID
read -p "Please enter the CLIENT_ID: " CLIENT_ID
read -p "Please enter the CLIENT_SECRET: " CLIENT_SECRET
read -p "Please enter the INGRESS_IP: " istio_endpoint
RESOURCE="https://management.azure.com/"
# Get JWT Token
TOKEN=$(curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&resource=$RESOURCE" https://login.microsoftonline.com/$TENANT_ID/oauth2/token | jq -r '.access_token')

# Number of requests to send
NUM_REQUESTS=$1

# Loop to send multiple requests
for ((i = 1; i <= NUM_REQUESTS; i++)); do
    # Get response code
    response_code=$(curl -H "Authorization: Bearer $TOKEN" -o /dev/null -s -w "%{http_code}" ${istio_endpoint}/hello)
    # Get response content
    RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" ${istio_endpoint}/hello)
    # Print response number, content, and response code
    echo "Request $i: $RESPONSE : $response_code"
done
