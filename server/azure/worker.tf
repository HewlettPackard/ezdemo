# Worker NICs
resource "azurerm_network_interface" "workernics" {
    count                = var.is_runtime ? var.worker_count + (var.is_mlops ? 3 : 0) : 0
    name                 = "worker${count.index + 1}-nic"
    location             = azurerm_resource_group.resourcegroup.location
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    ip_configuration {
        name                          = "worker${count.index + 1}-ip"
        subnet_id                     = azurerm_subnet.internal.id
        private_ip_address_allocation = "Dynamic"
    }
}

# Worker VMs
resource "azurerm_linux_virtual_machine" "workers" {
  count                 = var.is_runtime ? var.worker_count + (var.is_mlops ? 3 : 0) : 0
  name                  = "worker${count.index + 1}"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [element(azurerm_network_interface.workernics.*.id, count.index)]
  size                  = var.wkr_instance_type
  custom_data           = base64encode(file(pathexpand(var.cloud_init_file)))
  admin_username        = var.admin_user
  admin_ssh_key {
      username = var.admin_user
      public_key = file(pathexpand(var.ssh_pub_key_path))
  }
  os_disk {
      name              = "worker${count.index + 1}-disk0"
      caching           = "ReadWrite"
      disk_size_gb      = 400
      storage_account_type = "Standard_LRS"
  }
  source_image_reference {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7_9"
      version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storageaccount.primary_blob_endpoint
  }
}

/********** Data Disks **********/

locals {
  datadisks_count_map = { for k in toset(azurerm_linux_virtual_machine.workers.*.name) : k => 2 } // 2 disks per VM
  luns                      = { for k in local.datadisk_lun_map : k.datadisk_name => k.lun }
  datadisk_lun_map = flatten([
    for vm_name, count in local.datadisks_count_map : [
      for i in range(count) : {
        datadisk_name = format("%s-disk%01d", vm_name, i + 1)
        lun           = i + 1
      }
    ]
  ])
}

resource "azurerm_managed_disk" "wrkdatadisk" {
  for_each             = toset([for j in local.datadisk_lun_map : j.datadisk_name])
  name                 = each.key
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  create_option        = "Empty"
  disk_size_gb         = 500
  storage_account_type = "Standard_LRS"
}
resource "azurerm_virtual_machine_data_disk_attachment" "wrkdatadisk-attach" {
  for_each           = toset([for j in local.datadisk_lun_map : j.datadisk_name])
  managed_disk_id    = azurerm_managed_disk.wrkdatadisk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.workers[parseint(element(regex("^worker(\\d)-\\w*$", each.key), 0), 10) - 1].id
  lun                = lookup(local.luns, each.key)
  caching            = "ReadWrite"
}

## Outputs
output "workers_private_ip" {
  value = [azurerm_network_interface.workernics.*.private_ip_address]
}
output "workers_private_dns" {
  value = [ for g in azurerm_linux_virtual_machine.workers : [ "${g.name}.${azurerm_network_interface.workernics.0.internal_domain_name_suffix}" ] ]
}
output "worker_count" {
  value = var.is_runtime ? var.worker_count + (var.is_mlops ? 3 : 0) : 0
}
