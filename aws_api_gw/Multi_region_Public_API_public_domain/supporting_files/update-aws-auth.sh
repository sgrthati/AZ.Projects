#! /bin/bash
aws apigateway update-method \
      --rest-api-id $1 \
      --region $2 \
      --resource-id $3 \
      --http-method $4\
      --patch-operations op=replace,path=/apiKeyRequired,value=$5,from=body