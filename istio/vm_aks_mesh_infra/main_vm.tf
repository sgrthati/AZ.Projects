#module to create linux vm cluster,based on requirement you can disable by changing below variables
#we can add names variables here if we wanted created with that name
module "ProjectX" {
    source = "git::https://github.com/sgrthati/AZ.Terraform.git//modules/generic_resources/linux_vm?ref=main"
    resource_group_name = var.resource_group_name
    node_count = 1
    lb_enabled = false
    vm_pip_enabled = true
    dns_enabled = false
    dns_name = "internal.com"
    vm_os_sku = "18.04-LTS"
}