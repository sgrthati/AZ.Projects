#! /bin/bash
aws apigateway update-method \
      --rest-api-id $1 \
      --region $2 \
      --resource-id $3 \
      --http-method $4\
      --patch-operations op=replace,path=/apiKeyRequired,value=$5,from=body \
                         op=replace,path=/authorizationType,value=COGNITO_USER_POOLS,from=body \
                         op=replace,path=/authorizerId,value=$6,from=body \
                         op=add,path=/authorizationScopes,value="aws.cognito.signin.user.admin",from=body