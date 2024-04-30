# Azure Linux VM module
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

locals {
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  location            = "${var.location != "" ? var.location : data.azurerm_resource_group.main.location}"
  pip_name = "${var.pip_name != "" ? var.pip_name : "${var.resource_group_name}-vm-pip"}"
  nic_name = "${var.nic_name != "" ? var.nic_name : "${var.resource_group_name}-vm-nic"}"
  vm_name = "${var.vm_name != "" ? var.vm_name : "${var.resource_group_name}-vm"}"
  key_data = file("${var.ssh_key_path}")
  lb_backend_pool = "${var.vm_name != "" ? var.vm_name : "${var.resource_group_name}-vm-backend_pool"}"

  tags = "${merge(
    data.azurerm_resource_group.main.tags,
    var.tags
  )}"
}

module "vnet" {
    source = "git::https://github.com/sgrthati/AZ.Projects.git//terraform/modules/generic_resources/vnet?ref=main"
    resource_group_name = local.resource_group_name
}

resource "azurerm_public_ip" "pip" {
  name                = "${local.pip_name}-${count.index + 1}"
  count               =  var.vm_pip_enabled == true ? var.node_count : 0
  location            = "${local.location}"
  resource_group_name = "${local.resource_group_name}"
  allocation_method = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "${local.nic_name}-${count.index + 1}"
  count                 = var.node_count
  location            = "${local.location}"
  resource_group_name = "${local.resource_group_name}"

  ip_configuration {
    name                          = "${local.nic_name}-${count.index + 1}-ip"
    subnet_id                     = module.vnet.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = var.vm_pip_enabled == true ? element(azurerm_public_ip.pip.*.id,count.index) : null
  }

  tags = "${local.tags}"
}
module "lb" {
    source = "git::https://github.com/sgrthati/AZ.Projects.git//terraform/modules/generic_resources/loadbalancer?ref=main"
    resource_group_name = local.resource_group_name
    lb_enabled = var.lb_enabled
}
resource "azurerm_lb_backend_address_pool_address" "backend_pool_vm_assignment" {
  count = var.lb_enabled == true ? var.node_count : 0
  name                    = "${local.lb_backend_pool}-${count.index + 1}"
  backend_address_pool_id = module.lb.lb_backend_pool_id
  virtual_network_id      = module.vnet.vnet_id
  ip_address              = element(azurerm_network_interface.nic.*.private_ip_address, count.index)
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.node_count
  name                  = "${local.vm_name}-${count.index + 1}"
  location              = "${local.location}"
  resource_group_name   = "${local.resource_group_name}"
  computer_name         = "${local.vm_name}-${count.index + 1}"
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]
  admin_username = "${var.admin_username}"
  size             = "${var.vm_size}"
  custom_data = filebase64(var.customer_data_script)
  admin_ssh_key {
    username   = var.admin_username
    public_key = local.key_data
  }
  source_image_reference {
    publisher = "${var.vm_os_publisher != "" ? var.vm_os_publisher : var.vm_os_publisher}"
    offer     = "${var.vm_os_offer != "" ? var.vm_os_offer : var.vm_os_offer }"
    sku       = "${var.vm_os_sku != "" ? var.vm_os_sku : var.vm_os_sku}"
    version   = "${var.vm_os_version != "" ? var.vm_os_version : var.vm_os_version}"
  }
  
  os_disk {
    name = "${format("%.22s", lower("${var.vm_name}-osdisk"))}-${count.index + 1}"
    caching = "ReadWrite"
    storage_account_type =  var.managed_disk_type
    disk_size_gb = "${var.os_disk_size_gb != "" ? var.os_disk_size_gb : 128}"
  }

  #   provisioner "file" {
  #     source = var.script
  #     destination = "/tmp/script.sh"
  #   }
  #     provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /tmp/script.sh",
  #     "/tmp/script.sh args",
  #   ]
  # }
  #   connection {
  #     type        = "ssh"
  #     user        = "azureuser"
  #     port        = 22
  #     host        = azurerm_public_ip.notes-api-public-ip.ip_address
  #     private_key = file("~/.ssh/id_rsa")
  #   }

  tags = "${local.tags}"
}

module "pr_dns_zn" {
  source = "git::https://github.com/sgrthati/AZ.Projects.git//terraform/modules/generic_resources/private_dns_zone?ref=main"
  resource_group_name = var.resource_group_name
  depends_on = [ azurerm_linux_virtual_machine.vm ]
  dns_enabled = var.dns_enabled
  dns_name = var.dns_enabled == true ? var.dns_name : null
  dns_vnet_id = module.vnet.vnet_id
}

resource "azurerm_private_dns_a_record" "dns_record" {
  count = var.dns_enabled ==true ? var.node_count : 0
  name                =  var.dns_enabled == true ? "${local.vm_name}-${count.index + 1}" : null
  zone_name           = module.pr_dns_zn.private_dns_zone_name
  resource_group_name = local.resource_group_name
  ttl                 = 300
  records             = [element(azurerm_network_interface.nic.*.private_ip_address, count.index)]
}