# Worker NICs
resource "azurerm_network_interface" "maprnics" {
    count                = var.is_mapr ? var.is_mapr_ha ? var.mapr_count : 1 : 0
    name                 = "mapr${count.index + 1}-nic"
    location             = azurerm_resource_group.resourcegroup.location
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    ip_configuration {
        name                          = "mapr${count.index + 1}-ip"
        subnet_id                     = azurerm_subnet.internal.id
        private_ip_address_allocation = "Dynamic"
    }
}

# Worker VMs
resource "azurerm_linux_virtual_machine" "mapr" {
  count                 = var.is_mapr ? var.is_mapr_ha ? var.mapr_count : 1 : 0
  name                  = "mapr${count.index + 1}"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [element(azurerm_network_interface.maprnics.*.id, count.index)]
  size                  = var.mapr_instance_type
  admin_username        = var.admin_user
  admin_ssh_key {
      username = var.admin_user
      public_key = file(pathexpand(var.ssh_pub_key_path))
  }
  os_disk {
      name              = "mapr${count.index + 1}-disk0"
      caching           = "ReadWrite"
      disk_size_gb      = 400
      storage_account_type = "Standard_LRS"
  }
  source_image_reference {
      # publisher = "OpenLogic"
      # offer     = "CentOS"
      # sku       = "8_4"
      # version   = "latest"
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts-gen2"
      version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storageaccount.primary_blob_endpoint
  }
}

/********** Data Disks **********/

locals {
  maprdisks_count_map = { for k in toset(azurerm_linux_virtual_machine.mapr.*.name) : k => 1 } // 1 disks per VM
  maprluns            = { for k in local.maprdisk_lun_map : k.datadisk_name => k.lun }
  maprdisk_lun_map = flatten([
    for vm_name, count in local.maprdisks_count_map : [
      for i in range(count) : {
        datadisk_name = format("%s-disk%01d", vm_name, i + 1)
        lun           = i + 1
      }
    ]
  ])
}

resource "azurerm_managed_disk" "maprdatadisk" {
  for_each             = toset([for j in local.maprdisk_lun_map : j.datadisk_name])
  name                 = each.key
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  create_option        = "Empty"
  disk_size_gb         = 100
  storage_account_type = "Standard_LRS"
}
resource "azurerm_virtual_machine_data_disk_attachment" "maprdatadisk-attach" {
  for_each           = toset([for j in local.maprdisk_lun_map : j.datadisk_name])
  managed_disk_id    = azurerm_managed_disk.maprdatadisk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.mapr[parseint(element(regex("^mapr(\\d)-\\w*$", each.key), 0), 10) - 1].id
  lun                = lookup(local.maprluns, each.key)
  caching            = "ReadWrite"
}

## Outputs
output "mapr_private_ips" {
  value = azurerm_network_interface.maprnics.*.private_ip_address
}
output "mapr_private_dns" {
  value = azurerm_network_interface.maprnics.*.internal_domain_name_suffix
}
output "mapr_count" {
  value = var.is_mapr ? var.is_mapr_ha ? var.mapr_count : 1 : 0
}
