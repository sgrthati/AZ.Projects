#to install istiod:

    #for linux and mac
        `curl -L https://istio.io/downloadIstio | sh -`
    #for windows
        download from here > https://github.com/istio/istio/releases , name convention istio-<version>-win.zip,extract it

    and do below command    
    `istioctl install`

or

    `helm repo add istio https://istio-release.storage.googleapis.com/charts
    helm repo update
    kubectl create namespace istio-system
    helm install istio-base istio/base -n istio-system --set defaultRevision=default
    helm install istiod istio/istiod -n istio-system --wait
    helm install istio-ingress istio/gateway -n istio-system --wait`

#to install hello_worldv1&2

    `kubectl apply -f k8s_manifests\hello_world_deployment_istio_ingress\`

#to enable JWT
    `kubectl apply -f k8s_manifests\jwt\`
    # python script will create required JWK and Tocken,public&private.pem
    # python gen_keys.py >> tokens.txt
    # create a variable 'token' with generated JWT
    # for external_ip: external_ip=$(kubectl get svc -n istio-system -l app=istio-ingress -o jsonpath='{.item[0].status.loadBalancer.ingress[0].ip}')
    #test: curl -H "Authorization: Bearer $token" http://$external_ip/hello
#to enable logging in specified format
    # we have to upgrade istiod component,for that use below helm upgrade
    # helm upgrade  istiod istio/istiod -n istio-system -f k8s_manifests/logging/logging.yaml
    #logs can be viewed in kubectl get logs 'kubectl logs -l app=hello_world'