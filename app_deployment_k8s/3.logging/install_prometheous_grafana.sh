#variables
NAMESPACE_PROMETHEUS=prometheus
NAMESPACE_GRAFANA=grafana

set -xeuo pipefail
#installing prometheous via helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace $NAMESPACE_PROMETHEUS \
  --create-namespace

#installing Grafana via helm
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install grafana grafana/grafana \
  --namespace $NAMESPACE_GRAFANA \
  --create-namespace


#configure prometheus to scrape metrics
cat 3.logging/config/prometheus-values.yaml <<EOF
namespace: $NAMESPACE_PROMETHEUS
#to scrape the prometheus metrics
scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
    - role: pod
    scrape_interval: 5s
EOF

helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace $NAMESPACE_PROMETHEUS \
    --values 3.logging/config/prometheus-values.yaml \
    --wait

echo "Prometheus is ready"

#configure prometheus data source in Grafana

cat 3.logging/config/grafana-values.yaml <<EOF
namespace: $NAMESPACE_GRAFANA
service:
  type: LoadBalancer
  ports:
    - port: 3000
      targetPort: 3000

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus-server.$NAMESPACE_PROMETHEUS.svc.cluster.local:80
        isDefault: true
EOF

helm upgrade --install grafana grafana/grafana \
    --namespace $NAMESPACE_GRAFANA \
    --values 3.logging/config/grafana-values.yaml

echo "Grafana is ready"
grafana_password=$(kubectl get secret --namespace "${NAMESPACE_GRAFANA}" grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
grafana_endpoint=$(kubectl get svc --namespace "${NAMESPACE_GRAFANA}" grafana -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

cat <<EOF
1. Visit ${grafana_endpoint} to access Grafana.
2. Login with 
         username: admin
         password: ${grafana_password}
EOF

