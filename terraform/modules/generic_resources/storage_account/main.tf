data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

locals {
  storage_account_name = "${var.storage_account_name != "" ? var.storage_account_name : "${data.azurerm_resource_group.main.name}stracc"}"
  dns_asc_name = "${data.azurerm_resource_group.main.name}-pv-dns-asc"
  account_tier             = (var.account_kind == "FileStorage" ? "Premium" : split("_", var.skuname)[0])
  account_replication_type = (local.account_tier == "Premium" ? "LRS" : split("_", var.skuname)[1])
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location

  containers_list = [
    { name = "private", access_type = "private" },
    { name = "blob", access_type = "blob" },
    { name = "container", access_type = "container" }
  ]
  file_shares = [
    { name = "smbfileshare1", quota = 50 },
    { name = "smbfileshare2", quota = 50 }
  ]
  tables = ["table1", "table2", "table3"]
  queues = ["queue1", "queue2"]
  network_rules = { bypass = [], ip_rules = [], subnet_ids = [] }
  lifecycles = [
    {
      prefix_match               = ["container"]
      tier_to_cool_after_days    = 0
      tier_to_archive_after_days = 50
      delete_after_days          = 100
      snapshot_delete_after_days = 30
    },
    {
      prefix_match               = ["blob"]
      tier_to_cool_after_days    = 0
      tier_to_archive_after_days = 30
      delete_after_days          = 75
      snapshot_delete_after_days = 30
    }
  ]

  tags = "${merge(
    data.azurerm_resource_group.main.tags,
    var.tags
  )}"
}

module "user_managed_identity" {
  source = "/mnt/c/Users/User/Downloads/cluster/AZ.Projects/terraform/modules/generic_resources/identity"
  resource_group_name = var.resource_group_name
  sys_id_enabled = var.sys_id_enabled
}
# Storage Account Creation or selection 
resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "storeacc" {
  name                      = substr(format("%s%s", lower(replace(local.storage_account_name, "/[[:^alnum:]]/", "")), random_string.unique.result), 0, 24)
  depends_on = [ module.user_managed_identity ]
  resource_group_name       = local.resource_group_name
  location                  = local.location
  account_kind              = var.account_kind
  account_tier              = local.account_tier
  account_replication_type  = local.account_replication_type
  enable_https_traffic_only = true
  min_tls_version           = var.min_tls_version
  tags                      = local.tags
  identity {
    type = var.sys_id_enabled == true ? "SystemAssigned" : "SystemAssigned, UserAssigned"
    principal_id = var.sys_id_enabled == true ? "${module.user_managed_identity.mi_principal_id}" : null
    identity_ids = var.sys_id_enabled == false ? [module.user_managed_identity.mi_id] : null
  }
  }
#network rule
resource "azurerm_storage_account_network_rules" "example" {
  storage_account_id         = azurerm_storage_account.storeacc.id
  default_action             = "Deny"
  ip_rules                   = local.network_rules.ip_rules
  virtual_network_subnet_ids = local.network_rules.subnet_ids
  bypass                     = local.network_rules.bypass
}


# Storage Container Creation

resource "azurerm_storage_container" "container" {
  count                 = length(local.containers_list)
  name                  = local.containers_list[count.index].name
  storage_account_name  = azurerm_storage_account.storeacc.name
  container_access_type = local.containers_list[count.index].access_type
}


# Storage Fileshare Creation

resource "azurerm_storage_share" "fileshare" {
  count                = length(local.file_shares)
  name                 = local.file_shares[count.index].name
  storage_account_name = azurerm_storage_account.storeacc.name
  quota                = local.file_shares[count.index].quota
}


# Storage Tables Creation

resource "azurerm_storage_table" "tables" {
  count                = length(local.tables)
  name                 = local.tables[count.index]
  storage_account_name = azurerm_storage_account.storeacc.name
}


# Storage Queue Creation

resource "azurerm_storage_queue" "queues" {
  count                = length(local.queues)
  name                 = local.queues[count.index]
  storage_account_name = azurerm_storage_account.storeacc.name
}

# Storage Lifecycle Management
resource "azurerm_storage_management_policy" "lcpolicy" {
  count              = length(local.lifecycles) == 0 ? 0 : 1
  storage_account_id = azurerm_storage_account.storeacc.id

  dynamic "rule" {
    for_each = local.lifecycles
    iterator = rule
    content {
      name    = "rule${rule.key}"
      enabled = true
      filters {
        prefix_match = rule.value.prefix_match
        blob_types   = ["blockBlob"]
      }
      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = rule.value.tier_to_cool_after_days
          tier_to_archive_after_days_since_modification_greater_than = rule.value.tier_to_archive_after_days
          delete_after_days_since_modification_greater_than          = rule.value.delete_after_days
        }
        snapshot {
          delete_after_days_since_creation_greater_than = rule.value.snapshot_delete_after_days
        }
      }
    }
  }
}