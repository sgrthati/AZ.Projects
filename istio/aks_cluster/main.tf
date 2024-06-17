#create Azure Kubernetes Service
module "aks" {
  source                 = "git::https://github.com/sgrthati/AZ.Projects.git//terraform/modules/generic_resources/aks?ref=main"
  resource_group_name    = var.resource_group_name
}