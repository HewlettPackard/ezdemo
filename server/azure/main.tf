provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id
}

# Create a resource group
resource "azurerm_resource_group" "resourcegroup" {
  name     = "${var.project_id}-rg"
  location = var.region
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "network" {
    name                = "${var.project_id}-network"
    location            = azurerm_resource_group.resourcegroup.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    address_space       = [var.vpc_cidr_block]
}

# Create the subnet
resource "azurerm_subnet" "internal" {
    name                 = "${var.project_id}-internal"
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefixes       = [var.subnet_cidr_block]
}

# Storage account for all resources
resource "random_id" "storage_account" {
  byte_length = 8
}
resource "azurerm_storage_account" "storageaccount" {
    name                        = "${regex("[[:alnum:]]+",lower(var.project_id))}${lower(random_id.storage_account.hex)}"
    resource_group_name         = azurerm_resource_group.resourcegroup.name
    location                    = azurerm_resource_group.resourcegroup.location
    account_replication_type    = "LRS"
    account_tier                = "Standard"
}
