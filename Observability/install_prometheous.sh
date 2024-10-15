set -xeuo pipefail

#variables
NAMESPACE_PROMETHEUS=prometheus
storageClassName="azure-disk"

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

#configure prometheus to scrape metrics
cat > config/prometheus-values.yaml <<EOF
#namespace to deploy prometheus
namespace: $NAMESPACE_PROMETHEUS

#config of prometheus server
server:
#settingup promotheus to store logs in persistant dynamic expanding storage
  global:
    scrape_interval: 10s
    evaluation_interval: 10s
  #to set prometheus server type to Loadbalancer
  service:
    type: LoadBalancer
#to enable persistent volume.to store logs
  # persistentVolume:
  #   enabled: true
  #   storageClass: $storageClassName  # Set this to your Azure Disk StorageClass name
  #   accessModes:
  #     - ReadWriteOnce
  #   size: 50Gi  # Set your desired storage size
  #   mountPath: /data
#extra volume and volume mount for alert&recording rules
  extraVolumes:
  - name: recording-rules
    configMap:
      name: recording-rules
  - name: alerting-rules
    configMap:
      name: alerting-rules
  extraVolumeMounts:
  - name: recording-rules
    mountPath: /etc/prometheus/recording-rules
  - name: alerting-rules
    mountPath: /etc/prometheus/alerting-rules
#rule files to consider by prometheus
serverFiles:
  prometheus.yml:
    rule_files:
      - /etc/prometheus/recording-rules/*.yml
      - /etc/prometheus/alerting-rules/*.yml
#to scrape the prometheus metrics for pods and containers and services
  scrape_configs:
    - job_name: 'kubernetes-clusters'
      kubernetes_sd_configs:
      - role: cluster
    - job_name: node-exporter
      relabel_configs:
      - action: replace
        source_labels: [ __meta_kubernetes_pod_node_name]
        target_label: nodename
    - job_name: 'kubernetes-apiservers'
      kubernetes_sd_configs:
      - role: endpoints
    - job_name: 'kubernetes-containers'
      kubernetes_sd_configs:
      - role: container
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
    - job_name: 'kubernetes-services'
      kubernetes_sd_configs:
      - role: service
    - job_name: 'kubernetes-persistentvolumeclaims'
      kubernetes_sd_configs:
      - role: persistentvolumeclaim
    - job_name: 'kubernetes-persistentvolumes'
      kubernetes_sd_configs:
      - role: persistentvolume
    - job_name: 'kubernetes-cAdvisor'
      kubernetes_sd_configs:
      - role: node
    # - job_name: 'fluentd
    #   static_configs:
    #     - targets: ['fluentd-service.daemonset.svc.cluster.local:80']
#alert_manager_config
alertmanager:
  service:
    type: LoadBalancer
  
EOF

#creating a configmaps for recording_rules and alerting_rules
if ! kubectl get namespace $NAMESPACE_PROMETHEUS; then
kubectl create namespace $NAMESPACE_PROMETHEUS
fi

cat > config/recording_rules_manifest.yml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: recording-rules
  namespace: $NAMESPACE_PROMETHEUS
data:
  recording_rules.yml: |
$(cat config/recording_rules.yml | sed 's/^/    /')
EOF

cat > config/alerting_rules_manifest.yml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: alerting-rules
  namespace: $NAMESPACE_PROMETHEUS
data:
  alerting_rules.yml: |
$(cat config/alerting_rules.yml | sed 's/^/    /')
EOF

kubectl apply -f config/recording_rules_manifest.yml -n $NAMESPACE_PROMETHEUS
kubectl apply -f config/alerting_rules_manifest.yml -n $NAMESPACE_PROMETHEUS

helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace $NAMESPACE_PROMETHEUS \
    --values config/prometheus-values.yaml \
    --wait

echo "Prometheus is ready"
prometheus_endpoint=$(kubectl get svc -n $NAMESPACE_PROMETHEUS prometheus-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
alertmanager_endpoint=$(kubectl get svc -n $NAMESPACE_PROMETHEUS prometheus-alertmanager -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
cat <<EOF
Visit ${prometheus_endpoint} to access Prometheus
Visit ${alertmanager_endpoint}:9093 to access Alertmanager
EOF

