#! /bin/bash
aws apigateway update-method \
      --rest-api-id $1 \
      --region ap-south-2 \
      --resource-id $2 \
      --http-method $3\
      --patch-operations op=replace,path=/apiKeyRequired,value=$4