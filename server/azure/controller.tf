# Controller NIC
resource "azurerm_network_interface" "controllernics" {
  count                       = ( var.is_runtime ? ( var.is_ha ? 3 : 1) : 0)
  name                        = "controller-nic"
  location                    = azurerm_resource_group.resourcegroup.location
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  ip_configuration {
      name                          = "controller${count.index + 1}-ip"
      subnet_id                     = azurerm_subnet.internal.id
      private_ip_address_allocation = "Dynamic"
  }
}

# Controller VM
resource "azurerm_linux_virtual_machine" "controllers" {
  count                 = ( var.is_runtime ? ( var.is_ha ? 3 : 1) : 0)
  name                  = "ctrl${count.index + 1}"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [element(azurerm_network_interface.controllernics.*.id, count.index)]
  size                  = var.ctr_instance_type
  custom_data           = base64encode(file(pathexpand(var.cloud_init_file)))
  admin_username        = var.admin_user
  admin_ssh_key {
      username = var.admin_user
      public_key = file(pathexpand(var.ssh_pub_key_path))
  }
  os_disk {
      name              = "controller${count.index + 1}-disk0"
      caching           = "ReadWrite"
      disk_size_gb      = "400"
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
  ctrdatadisks_count_map = { for k in toset(azurerm_linux_virtual_machine.controllers.*.name) : k => 1 } // 1 disks per VM
  ctrluns                      = { for k in local.ctrdatadisk_lun_map : k.datadisk_name => k.lun }
  ctrdatadisk_lun_map = flatten([
    for vm_name, count in local.ctrdatadisks_count_map : [
      for i in range(count) : {
        datadisk_name = format("%s-disk%01d", vm_name, i + 1)
        lun           = i + 1
      }
    ]
  ])
}

resource "azurerm_managed_disk" "ctrdatadisk" {
  for_each             = toset([for j in local.ctrdatadisk_lun_map : j.datadisk_name])
  name                 = each.key
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  create_option        = "Empty"
  disk_size_gb         = 500
  storage_account_type = "Standard_LRS"
}
resource "azurerm_virtual_machine_data_disk_attachment" "ctrdatadisk-attach" {
  for_each           = toset([for j in local.ctrdatadisk_lun_map : j.datadisk_name])
  managed_disk_id    = azurerm_managed_disk.ctrdatadisk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.controllers[parseint(element(regex("^ctrl(\\d)-\\w*$", each.key), 0), 10) - 1].id
  lun                = lookup(local.ctrluns, each.key)
  caching            = "ReadWrite"
}

## Outputs
output "controller_private_ips" {
    value = [ azurerm_network_interface.controllernics.*.private_ip_address ]
}
output "controller_private_dns" {
  value = [[ for g in azurerm_linux_virtual_machine.controllers : [ "${g.name}.${azurerm_network_interface.controllernics.0.internal_domain_name_suffix}" ] ]]
}