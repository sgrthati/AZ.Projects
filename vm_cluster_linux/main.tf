module "vet" {
    source = "./terraform/modules/generic_resources/vnet"

}
module "ProjectX" {
    source = "./terraform/modules/linux_vm"
}