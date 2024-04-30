
module "ProjectX" {
    source = "C:/Users/User/Downloads/cluster/AZ.Projects/terraform/modules/linux_vm/"
    resource_group_name = var.resource_group_name
    node_count = 2
    lb_enabled = false
    vm_pip_enabled = true
    dns_enabled = true
    dns_name = "Internal.com"
}