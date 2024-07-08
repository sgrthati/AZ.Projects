#!/bin/bash
#Delete pre existing VM_istio_config files
FILES_TO_DELETE=("vm_workload_config/cluster.env" "vm_workload_config/hosts" "vm_workload_config/istio-token" "vm_workload_config/mesh.yaml" "vm_workload_config/root-cert.pem")
for file in "${FILES_TO_DELETE[@]}"; do
    # Check if the file exists
    if [ -e "$file" ]; then
        echo "Deleting $file..."
        # Perform the deletion
        rm "$file"
        echo "$file deleted."
    else
        echo "$file does not exist. Skipping deletion."
    fi
done
set -euxo pipefail
#read the vm_public_ip
read -p "Please enter the public IP: " VM_PUBLIC_IP
#variables
CTX_CLUSTER1="sri-aks-cluster-admin"
VM_NAMESPACE="vm-workloads"
SERVICE_ACCOUNT="vm-svc-account"
ISTIO_VM_CONFIG_DIR="vm_workload_config/"
CLUSTER="sri-aks-cluster"
PRIVATE_KEY="/mnt/c/Users/User/Downloads/cluster/AZ.Projects/istio/vm_aks_mesh_infra/keys/private_key"
FILES_TO_DELETE=("vm_workload_config/cluster.env" "vm_workload_config/hosts" "vm_workload_config/istio-token" "vm_workload_config/mesh.yaml" "vm_workload_config/root-cert.pem")
#Delete pre existing VM_istio_config files
for file in "${FILES_TO_DELETE[@]}"; do
    # Check if the file exists
    if [ -e "$file" ]; then
        echo "Deleting $file..."
        # Perform the deletion
        rm "$file"
        echo "$file deleted."
    else
        echo "$file does not exist. Skipping deletion."
    fi
done
# Check if istioctl is installed
if ! command -v istioctl &> /dev/null
then
    echo "istioctl not found, proceeding with installation."
    # Define the version of Istio you want to install
    ISTIO_VERSION=1.22.2
    # Download Istio
    curl -sL https://istio.io/downloadIstioctl | sh -
    export PATH=$HOME/.istioctl/bin:$PATH
    # Verify the installation
    istioctl version
    # Configure Istio (this is a placeholder, add your specific configuration commands here)
    echo "Configuring Istio..."      
else
    echo "istioctl is already installed."
fi

#create a namespace for istio-system
if ! kubectl create namespace istio-system; then 
 echo "Namespace istio-system already exists, skipping creation."
 fi
if ! kubectl label namespace istio-system topology.istio.io/network=k8s-network; then
 echo "Namespace label already applied, skipping."
 fi

#install istio in cluster along with required values
istioctl  install -y -f ./istio_k8s_setup/istio_installation.yaml

#install istio_east_west_gw to allow traffic from VM workloads
istioctl  install -y -f ./istio_k8s_setup/istio_east_west_gw.yaml

#to expose istiod services to outside
if ! kubectl apply -n istio-system -f expose/ ; then
    echo "istiod service already exposed"
    fi
#Create the namespace that will host the virtual machine
if ! kubectl create namespace "${VM_NAMESPACE}"; then
    echo "${VM_NAMESPACE} already created"
    fi

#Create a serviceaccount for the virtual machine
if ! kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}"; then
    echo ""${SERVICE_ACCOUNT}" already create"
    fi
#create a workload group for adding vms to istio
if ! kubectl apply -f workloadgroup.yaml; then
    echo "workload group already created"
    fi
#for istio_vm_config we have to pass workload group template to istioctl
istioctl x workload entry configure -f workloadgroup.yaml --name "${SERVICE_ACCOUNT}" --clusterID "${CLUSTER}" --externalIP "${VM_PUBLIC_IP}" --autoregister -o "${ISTIO_VM_CONFIG_DIR}"

#moving generated config to VM
sudo scp -i "${PRIVATE_KEY}" vm_workload_config/* linuxadmin@"${VM_PUBLIC_IP}":/tmp/
