# AZ.Projects

- we will going to use terraform modules availables in [Az.Terraform](https://github.com/sgrthati/AZ.Terraform.git) for all projects in these repo
- we will customize terraform modules based on project requirement
- for every project i will create seperate folder and in that i will put terraform module along with Project Data files
- in terraform every module can able to provision a resource without passing variables,here for all modules we have to pass **`resource_group_name`** there only it is going to provision,that resource group should be existed
- every terraform module can be customizable based on our requirement
- in each project detailed Readme available in that Dir
- Suggestions & feedback are always give us a way to pushing in a way forward
  
# Projects:

## [1. Hands on Istio Labs](/istio/)
- #### [App v1&2 deployment,canary deployment demo](/istio/labs/hello_world_deployment_istio_ingress/)
- #### [enable JWT](/istio/labs/jwt/)
- #### [3rd party JWT(AzureAD)](/istio/labs/3rd_party_jwt_azure_ad/)
- #### [add VM Workload to istio](/istio/labs/add_vm_to_istio/with_helm_charts/)
## [2. Hello world Application deployment in K8s](/app_deployment_k8s/)
- ####  [Hello World App v1&2 deployment](/app_deployment_k8s/1.app/)
  - ###### [using deployments](/app_deployment_k8s/1.app/deployment/)
  - ###### [using statefulset](/app_deployment_k8s/1.app/statefulset/)
- ####  [configmap,secrets as a variables&volume](/app_deployment_k8s/1.app/configmap_secrets/)
- ####  [Nginx Ingress](/app_deployment_k8s/2.ingress/)
- #### [Prometheus & Grafana](/app_deployment_k8s/3.logging/)