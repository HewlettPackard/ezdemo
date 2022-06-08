# GPU Worker NICs
resource "azurerm_network_interface" "gworkernics" {
    count                = var.gworker_count
    name                 = "gworker${count.index + 1}-nic"
    location             = azurerm_resource_group.resourcegroup.location
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    ip_configuration {
        name                          = "gworker${count.index + 1}-ip"
        subnet_id                     = azurerm_subnet.internal.id
        private_ip_address_allocation = "Dynamic"
    }
}

# GPU Worker VMs
resource "azurerm_linux_virtual_machine" "gworkers" {
  count                 = var.gworker_count
  name                  = "gworker${count.index + 1}"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [element(azurerm_network_interface.gworkernics.*.id, count.index)]
  size                  = var.gpu_instance_type
  admin_username        = var.admin_user
  admin_ssh_key {
      username = var.admin_user
      public_key = file(pathexpand(var.ssh_pub_key_path))
  }
  os_disk {
      name              = "gworker${count.index + 1}-disk0"
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
  gdatadisks_count_map = { for k in toset(azurerm_linux_virtual_machine.gworkers.*.name) : k => 2 } // 2 disks per VM
  gluns                      = { for k in local.gdatadisk_lun_map : k.datadisk_name => k.lun }
  gdatadisk_lun_map = flatten([
    for vm_name, count in local.gdatadisks_count_map : [
      for i in range(count) : {
        datadisk_name = format("%s-disk%01d", vm_name, i + 1)
        lun           = i + 1
      }
    ]
  ])
}

resource "azurerm_managed_disk" "gwrkdatadisk" {
  for_each             = toset([for j in local.gdatadisk_lun_map : j.datadisk_name])
  name                 = each.key
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  create_option        = "Empty"
  disk_size_gb         = 500
  storage_account_type = "Standard_LRS"
}
resource "azurerm_virtual_machine_data_disk_attachment" "gwrkdatadisk-attach" {
  for_each           = toset([for j in local.gdatadisk_lun_map : j.datadisk_name])
  managed_disk_id    = azurerm_managed_disk.gwrkdatadisk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.gworkers[parseint(element(regex("^gworker(\\d)-\\w*$", each.key), 0), 10) - 1].id
  lun                = lookup(local.gluns, each.key)
  caching            = "ReadWrite"
}

## Outputs
output "gworker_private_ips" {
  value = azurerm_network_interface.gworkernics.*.private_ip_address
}
output "gworkers_private_dns" {
  value = azurerm_network_interface.gworkernics.*.internal_domain_name_suffix
}
output "gworker_count" {
  value = var.gworker_count
}
