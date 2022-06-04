resource "random_id" "gw_dns" {
  byte_length = 2
}

# Gateway Public IP
resource "azurerm_public_ip" "gatewaypip" {
  count                        = var.is_ha ? 2 : 1
  name                         = "gateway${count.index + 1}-pip"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  allocation_method            = "Static"
  domain_name_label            = "${regex("[a-z0-9]+", lower(var.project_id))}${lower(random_id.gw_dns.hex)}${count.index}"
}

# Gateway NIC
resource "azurerm_network_interface" "gatewaynics" {
  count                       = var.is_ha ? 2 : 1
  name                        = "gateway${count.index + 1}-nic"
  location                    = azurerm_resource_group.resourcegroup.location
  resource_group_name         = azurerm_resource_group.resourcegroup.name
  ip_configuration {
      name                          = "gateway${count.index +1}-ip"
      subnet_id                     = azurerm_subnet.internal.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.gatewaypip[count.index].id
  }
}

# Gateway VM
resource "azurerm_linux_virtual_machine" "gateways" {
  count                 = var.is_ha ? 2 : 1
  name                  = "gw${count.index + 1}"
  computer_name         = "${replace(var.project_id,"_","")}-${count.index + 1}" // to avoid gateway name for vnet
  location              = azurerm_resource_group.resourcegroup.location
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [azurerm_network_interface.gatewaynics[count.index].id]
  size                  = var.gtw_instance_type
  admin_username        = var.admin_user
  admin_ssh_key {
      username = var.admin_user
      public_key = file(pathexpand(var.ssh_pub_key_path))
  }
  os_disk {
      name              = "gateway${count.index + 1}-os-disk"
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

resource "azurerm_network_security_group" "gatewaynsg" {
  name                = "allow_gateway"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "allow_ecp_ports"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_ranges    = [22, 443, 8080, 8443, "10000-50000"]
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_network_interface_security_group_association" "nsgforgateway" {
  count                     = length(azurerm_network_interface.gatewaynics.*.id)
  network_interface_id      = element(azurerm_network_interface.gatewaynics.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.gatewaynsg.id
}

## Outputs
output "gateway_private_ips" {
  value = azurerm_network_interface.gatewaynics.*.private_ip_address
}
output "gateway_private_dns" {
  value = azurerm_network_interface.gatewaynics.*.internal_domain_name_suffix
}

output "gateway_public_ips" {
  value = azurerm_public_ip.gatewaypip.*.ip_address
}
output "gateway_public_dns" {
  value = azurerm_public_ip.gatewaypip.*.fqdn
}
