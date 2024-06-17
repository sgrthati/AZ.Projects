#script used for to ping multiple times
#script.sh <no.of pings>
#./script.sh 10
#!/bin/bash
NUM_REQUESTS=$1
#ingress gw ip
external_ip=$(kubectl get svc -n istio-system -l app=istio-ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
for ((i = 1; i <= NUM_REQUESTS; i++)); do
     #curl response code
    response_code=$(curl -s -w "%{http_code}" -o /dev/null ${external_ip}/hello)
    RESPONSE=$(curl -s ${external_ip}/hello)
    echo {$i: $RESPONSE:  $response_code}
    done