#!/bin/bash
# script used for to ping multiple times
# script.sh <no.of pings>
# ./script.sh 10
NUM_REQUESTS=$1
#ingress gw ip
istio_endpoint=$(kubectl get svc -n istio-system -l app=istio-ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
for ((i = 1; i <= NUM_REQUESTS; i++)); do
    #curl response code
    response_code=$(curl -s -w "%{http_code}" -o /dev/null ${istio_endpoint}/hello)
    RESPONSE=$(curl -s ${istio_endpoint}/hello)
    echo {$i: $RESPONSE :  $response_code}
    done