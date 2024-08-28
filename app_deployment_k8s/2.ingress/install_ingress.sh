#Variables
VERSION="4.11.2"
NAMESPACE="ingress-nginx"

set -xeuo pipefail
#install nginx-ingress through helm
#to preserve client source IP,we have set the externalTrafficPolicy to Local
#to enable logging we have set the log-format-escape-json to true
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --version ${VERSION} \
    --namespace ${NAMESPACE} \
    --create-namespace \
    --values 2.ingress/config/ingress-values.yaml

echo "ingress-nginx installed successfully"
