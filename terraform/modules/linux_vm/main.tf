# Azure Linux VM module
data "azurerm_resource_group" "main" {
  name = "${var.resource_group_name}"
}

locals {
  resource_group_name = "${data.azurerm_resource_group.main.name}"
  location            = "${var.location != "" ? var.location : data.azurerm_resource_group.main.location}"
  pip_name = "${var.pip_name != "" ? var.pip_name : "${var.resource_group_name}-vm-pip"}"
  nic_name = "${var.nic_name != "" ? var.nic_name : "${var.resource_group_name}-vm-nic"}"
  vm_name = "${var.vm_name != "" ? var.vm_name : "${var.resource_group_name}-vm"}"
  key_data = "${var.admin_public_key != "" ? var.admin_public_key : file("${var.ssh_key_path}")}"

  tags = "${merge(
    data.azurerm_resource_group.main.tags,
    var.tags
  )}"

  disk_sha1 = "${sha1("${var.resource_group_name}${var.vm_name}")}"
}

resource "azurerm_public_ip" "pip" {
  name                = "${local.pip_name}-${count.index}"
  count                 = "${var.node_count != "" ? var.node_count : null}"
  location            = "${local.location}"
  resource_group_name = "${local.resource_group_name}"
}

resource "azurerm_network_interface" "nic" {
  name                = "${local.nic_name}-${count.index}"
  count                 = "${var.node_count != "" ? var.node_count : 1}"
  location            = "${local.location}"
  resource_group_name = "${local.resource_group_name}"

  ip_configuration {
    name                          = "${local.nic_name}-${count.index}-ip"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags = "${local.tags}"
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = "${var.node_count != "" ? var.node_count : null}"
  name                  = "${local.vm_name}-${count.index}"
  location              = "${local.location}"
  resource_group_name   = "${local.resource_group_name}"
  network_interface_ids = ["${var.node_count != "" ? element(concat(azurerm_network_interface.nic.*.id, list("")), count.index) : azurerm_network_interface.nic.id))}"]

  size             = "${var.vm_size}"

  delete_os_disk_on_termination = "${var.delete_os_disk_on_termination}"

  source_image_reference {
    id        = "${var.vm_os_id}"
    publisher = "${var.vm_os_id == "" ? var.vm_os_publisher : ""}"
    offer     = "${var.vm_os_id == "" ? var.vm_os_offer : ""}"
    sku       = "${var.vm_os_id == "" ? var.vm_os_sku : ""}"
    version   = "${var.vm_os_id == "" ? var.vm_os_version : ""}"
  }
  
  os_disk {
    name = "${format("%.22s", lower("${var.vm_name}-osdisk"))}-${count.index}"
    caching = "ReadWrite"
    storage_account_type =  var.managed_disk_type
    disk_size_gb = "${var.os_disk_size_gb != "" ? var.os_disk_size_gb : 128}"
  }

  os_profile {
    computer_name  = "${var.node_count != "" ? var.vm_name : var.vm_name}-${count.index}"
    admin_username = "${var.admin_username}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${local.key_data}"
    }
  }

  boot_diagnostics {
    enabled     = "${var.boot_diagnostics_storage_uri != "" ? true : false}"
    storage_uri = "${var.boot_diagnostics_storage_uri}"
  }

  tags = "${local.tags}"
}

resource "azurerm_managed_disk" "dd" {
  count                 = "${var.node_count != "" ? var.node_count : null}"
  name                 = "${format("%.22s", lower("${local.vm_name}-disk"))}-${count.index}"
  resource_group_name  = "${local.resource_group_name}"
  location             = "${local.location}"
  storage_account_type = "${var.managed_disk_storage_account_type}"
  create_option        = "${var.managed_disk_create_option}"
  disk_size_gb         = "${var.managed_disk_size_gb}"

  tags = "${local.tags}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count                 = "${var.node_count != "" ? var.node_count : null}"  
  virtual_machine_id = ["${var.node_count != "" ? element(concat(azurerm_linux_virtual_machine.vm.*.id, list("")), count.index) : azurerm_linux_virtual_machine.vm.id))}"]
  managed_disk_id    = ["${var.node_count != "" ? element(concat(azurerm_managed_disk.dd.*.id, list("")), count.index) : azurerm_managed_disk.dd.id))}"]
  lun                = 0
  caching            = "ReadWrite"
}