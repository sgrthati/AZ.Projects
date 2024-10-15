#variables
NAMESPACE_GRAFANA=grafana
read -p "Enter the prometheus endpoint: " prometheus_endpoint
storageClassName="azure-disk"
set -xeuo pipefail

# #creating storageClass in cluster
# cat > config/storageClass.yaml <<EOF
# apiVersion: storage.k8s.io/v1
# kind: StorageClass
# metadata:
#   name: $storageClassName
# provisioner: kubernetes.io/azure-disk
# parameters:
#   skuName: Premium_LRS
#   kind: Managed
#   location: centralindia
# allowVolumeExpansion: true
# reclaimPolicy: Retain
# volumeBindingMode: Immediate
# EOF
# #installing storage class in cluster
# kubectl apply -f config/storageClass.yaml


#configure prometheus data source in Grafana
cat > config/grafana-values.yaml <<EOF
namespace: $NAMESPACE_GRAFANA
service:
  type: LoadBalancer
  ports:
    - port: 3000
      targetPort: 3000
      protocol: TCP
#persistence volume
# persistence:
#   enabled: true
#   storageClassName: $storageClassName  # Set this to your Azure Disk StorageClass name
#   accessModes:
#     - ReadWriteOnce
#   size: 10Gi  # Set your desired storage size
#adding prometheus datasource
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://$prometheus_endpoint:80
        isDefault: true
#grafana configuration
grafana.ini:
  paths:
    data: /var/lib/grafana/data
  log:
    mode: console
  database:
    type: sqlite3
    path: grafana.db
#autoload dashboards
sidecar:
  dashboards:
    enabled: true
    folder: /var/lib/grafana/dashboards/default
    searchNamespace: ALL
    label: grafana_dashboard
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'k8s'
      orgId: 1
      folder: ''
      type: file
      allowUiUpdates: true
      disableDeletion: true
      editable: true
      options:
        path: /var/lib/grafana/dashboards/k8s
dashboards:
  k8s:
    k8s:
      file: dashboards/6417_rev1.json
  prometheus:
    prometheus-stats:
      gnetId: 2
      revision: 2
      datasource: Prometheus

EOF
#download grafana helm chart into config directory
rm -rf config/helm-charts/*
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm pull grafana/grafana --untar --untardir config/helm-charts

#copy dashboards to helm dashboards directory
cp -r config/dashboards/*.json config/helm-charts/grafana/dashboards

helm upgrade --install grafana ./config/helm-charts/grafana  \
    --namespace $NAMESPACE_GRAFANA \
    --values config/grafana-values.yaml \
    --create-namespace \
    --wait 

echo "Grafana is ready"
grafana_password=$(kubectl get secret --namespace "${NAMESPACE_GRAFANA}" grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
grafana_endpoint=$(kubectl get svc --namespace "${NAMESPACE_GRAFANA}" grafana -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

cat <<EOF
1. Visit ${grafana_endpoint} to access Grafana.
2. Login with the following credentials:
         username: admin
         password: ${grafana_password}
EOF