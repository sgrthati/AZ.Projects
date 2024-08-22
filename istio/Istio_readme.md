# to provision AKS Cluster

#inside aks_cluster,change the variable resource_group_name with exisitng resource group name

    cd ./istio/aks_cluster
    terraform apply

#it will provision AKS cluster,here we are going to perform istio labs


# to install istiod:
#for linux and mac
       
    curl -L https://istio.io/downloadIstio | sh -

#for windows download from here https://github.com/istio/istio/releases, name convention istio-version-win.zip,extract it
  
    istioctl install

or

#use helm charts to install,here istio-system is namespace,where we are installing istio components

    helm repo add istio https://istio-release.storage.googleapis.com/charts
    helm repo update
    kubectl create namespace istio-system
    helm install istio-base istio/base -n istio-system --set defaultRevision=default
    helm install istiod istio/istiod -n istio-system --wait
    helm install istio-ingressgateway istio/gateway -n istio-system --wait

# to install hello_world deployment,like canary,blue-green deployment
    
    cd ./istio/labs/
    kubectl apply -f ./labs/hello_world_deployment_istio_ingress/

#this will install helloworldv1&2 along with service,virtualsvc,gateway

#to access the application run below script along with no.of pings

    ./labs/ping.sh 20

#in output terminal,we can see request bifurcation

# to enable JWT

#python script will create required JWK and Tocken,public&private.pem

    python labs/jwt/gen_keys.py >> tokens.txt

#generated JWK,we have to replace in auth.yaml(line No,15-19)

    kubectl apply -f labs\jwt\

#create a variable 'token' with generated JWT

#for istio_endpoint:

    istio_endpoint=$(kubectl get svc -n istio-system -l app=istio-ingress -o jsonpath='{.item[0].status.loadBalancer.ingress[0].ip}')

#ping: 

    curl -H "Authorization: Bearer $token" http://$istio_endpoint/hello

# to enable logging in specified format

#we have to upgrade istiod component,for that use below helm upgrade

    helm upgrade  istiod istio/istiod -n istio-system -f labs/logging/logging.yaml

#logs can be viewed at after doing multiple pings to istio_endpoint: 

    kubectl logs -l app=istio-ingress -n istio-system


#   to enable 3rd party JWT using azure ad
#here we are using AzureAD as a 3rd Party JWT

#update tenantID in 3rd_party_jwt_azure_ad manifest files

    kubectl apply -f labs/3rd_party_jwt_azure_ad/

#use labs/3rd_party_jwt_azure_ad/ping.sh to access our app
    
    Usage:
    What the script does:
        Checks Azure login
        Asks for authentication method (Azure AD or Service Principal)
        Gets authentication token
        Sends multiple requests to Azure endpoint
        Prints response content and code
        
    How to use the script:
        Save the script to a file (e.g. azure_request.sh)
        Make the script executable (chmod +x azure_request.sh)
        Run the script (./azure_request.sh)
        Choose authentication method
        Enter authentication details (if Service Principal)
        Specify number of requests ./azure_request.sh 10
        Review the output

