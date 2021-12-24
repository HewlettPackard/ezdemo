# NIC
resource "azurerm_network_interface" "ad_servernic" {
    name                        = "ad_server-nic"
    location                    = azurerm_resource_group.resourcegroup.location
    resource_group_name         = azurerm_resource_group.resourcegroup.name
    ip_configuration {
        name                          = "ad_server-ip"
        subnet_id                     = azurerm_subnet.internal.id
        private_ip_address_allocation = "Dynamic"
     }
}

resource "azurerm_linux_virtual_machine" "ad_server" {
  name                  = "ad-server"
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.ad_servernic.id]
  size                  = var.ad_instance_type
  admin_username        = var.admin_user
  custom_data           = base64encode(file(pathexpand(var.cloud_init_file)))
  admin_ssh_key {
      username = var.admin_user
      public_key = file(pathexpand(var.ssh_pub_key_path))
  }
  os_disk {
      name              = "ad-server-os-disk"
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

## Outputs
output "ad_server_private_ip" {
  value = azurerm_network_interface.ad_servernic.private_ip_address
}
