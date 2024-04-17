variable "resource_group_name" {
  description = "(Required) The name of the resource group in which the resources will be created"
}

variable "location" {
  description = "(Optional) The location/region where the virtual machines will be created. Uses the location of the resource group by default."
  default     = ""
}

variable "subnet_id" {
  description = "(Required) The subnet id of the virtual network where the virtual machines will reside."
}

variable "tags" {
  type        = "map"
  description = "(Optional) A map of the tags to use on the resources that are deployed with this module. Tags will be merged with those defined by the resource group."

  default = {
    source = "Terraform"
    Environment = "Test"
  }
}

variable "vm_size" {
  description = "Azure VM Size to use. See: https://docs.microsoft.com/en-us/azure/cloud-services/cloud-services-sizes-specs"
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  description = "(Optional) Specifies the size of the os disk in gigabytes. Default 32 GB"
  default     = "32"
}

variable "admin_public_key" {
  description = "Optionally supply the admin public key. If provided, will override variable: sshKey"
  default     = ""
}

variable "ssh_key_path" {
  description = "Path to the public key to be used for ssh access to the VM. Default is ~/.ssh/id_rsa.pub. If specifying a path to a certification on a Windows machine to provision a linux vm use the / in the path versus backslash. e.g. c:/home/id_rsa.pub"
  default     = "~/.ssh/id_rsa.pub"
}

variable "node_count" {
  description = "The number of Nodes to create"
  default     = 1
}

variable "admin_username" {
  description = "Specifies the name of the administrator account."
  default     = "linuxadmin"
}

variable "custom_data" {
  description = "(Optional) Specifies custom data to supply to the machine. On linux-based systems, this can be used as a cloud-init script. On other systems, this will be copied as a file on disk. Internally, Terraform will base64 encode this value before sending it to the API. The maximum length of the binary array is 65535 bytes."
  default     = ""
}

variable "data_disk" {
  description = "Create Virtual Machine with attached managed data disk. Default false"
  default     = "false"
}
