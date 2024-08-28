#create Azure Kubernetes Service
module "aks" {
  source                 = "git::https://github.com/sgrthati/AZ.Terraform.git//modules/generic_resources/aks?ref=main"
  resource_group_name    = var.resource_group_name
  user_principal_name    = var.user_principal_name
}