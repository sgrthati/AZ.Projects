
module "ProjectX" {
    source = "git::https://github.com/sgrthati/AZ.Projects.git//terraform/modules/generic_resources/modules/linux_vm?ref=main"
    resource_group_name = var.resource_group_name
    node_count = 2
    lb_enabled = false
    vm_pip_enabled = true
    dns_enabled = true
    dns_name = "Internal.com"
}