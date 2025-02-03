#variables
aws configure set region ap-south-2
aws --region ap-south-2 apigateway test-invoke-method \
    --rest-api-id 3cxxh0hdhk \
    --resource-id quxkni \
    --http-method GET