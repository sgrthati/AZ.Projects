#!/bin/bash
# set -euxo pipefail
API_URL="https://api.example.int/api/posts/1"
COGNITO_IDP_URL="https://cognito-idp.ap-south-1.amazonaws.com"
CLIENT_ID="a5a57cds20r2qgo002v2nqo6e"
CLIENT_SECRET="pns5f8ahtp2mr2r26im52hfv2oeo3kpjsgshvsk2j2rqhhalo2d"
USERNAME="test"
PASSWORD="Example@2025"

#install jq
if ! command -v jq &> /dev/null
then
  echo "jq could not be found. Installing..."
  sudo apt-get install -y jq
fi
# HMAC Computed hash -- SHA256 with key CLIENT_SECRET of USERNAME+CLIENT_ID and base64'd
# See: https://docs.aws.amazon.com/cognito/latest/developerguide/signing-up-users-in-your-app.html#cognito-user-pools-computing-secret-hash
SECRET_HASH=$(echo -n "${USERNAME}${CLIENT_ID}" | openssl dgst -sha256 -hmac ${CLIENT_SECRET} -binary | openssl enc -base64)

# Include SECRET_HASH if app client generates client_secret
response=$(curl -s --location --request POST $COGNITO_IDP_URL \
  --header 'X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth' \
  --header 'Content-Type: application/x-amz-json-1.1' \
  --data-raw "{
    \"AuthFlow\": \"USER_PASSWORD_AUTH\",
    \"AuthParameters\": {
        \"USERNAME\": \"$USERNAME\",
        \"PASSWORD\": \"$PASSWORD\",
        \"SECRET_HASH\": \"$SECRET_HASH\"
    },
    \"ClientId\": \"$CLIENT_ID\"
}")

ACCESS_TOKEN=$(echo "$response" | jq -r '.AuthenticationResult.AccessToken')

# echo "Access Token: $ACCESS_TOKEN"

curl -s -H "Authorization: Bearer $ACCESS_TOKEN" $API_URL

