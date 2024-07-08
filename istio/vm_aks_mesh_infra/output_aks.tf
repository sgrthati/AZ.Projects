# output "kube_config" {
#   description = "Kube config"
#   value       = module.aks.kube_config
#   sensitive = true
# }

# output "host" {
#   description = "Kube host"
#   value       = module.aks.host
#   sensitive = true
# }

output "download_aks_credetials" {
  value = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${module.aks.cluster_name} --overwrite-existing --admin"
}