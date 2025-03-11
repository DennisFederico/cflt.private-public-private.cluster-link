##### RESOURCE GROUPS
data "azurerm_resource_group" "hub_resource_group" {
  name = var.hub_resource_group_name
}

# Create a new resource group if needed
data "azurerm_resource_group" "primary_resource_group" {
  name = var.primary_resource_group_name
}

# Create a new resource group if needed
data "azurerm_resource_group" "dr_resource_group" {
  name = var.dr_resource_group_name
}

##### VIRTUAL NETWORKS
# Retrieve the existing virtual network
data "azurerm_virtual_network" "hub_vnet" {
  name                = var.hub_vnet_name
  resource_group_name = var.hub_resource_group_name
}

data "azurerm_virtual_network" "primary_vnet" {
  name                = var.primary_vnet_name
  resource_group_name = data.azurerm_resource_group.primary_resource_group.name
}

data "azurerm_virtual_network" "dr_vnet" {
  name                = var.dr_vnet_name
  resource_group_name = data.azurerm_resource_group.dr_resource_group.name
}

# Peering from primary to Hub
resource "azurerm_virtual_network_peering" "primary_to_hub_peering" {
  name                         = "${var.primary_vnet_name}-to-${var.hub_vnet_name}-peering"
  resource_group_name          = data.azurerm_resource_group.primary_resource_group.name
  virtual_network_name         = data.azurerm_virtual_network.primary_vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Peering from Hub primary
resource "azurerm_virtual_network_peering" "hub_to_primary_peering" {
  name                         = "${var.hub_vnet_name}-to-${var.primary_vnet_name}-peering"
  resource_group_name          = data.azurerm_resource_group.hub_resource_group.name
  virtual_network_name         = data.azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.primary_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Peering from dr to Hub
resource "azurerm_virtual_network_peering" "dr_to_hub_peering" {
  name                         = "${var.dr_vnet_name}-to-${var.hub_vnet_name}-peering"
  resource_group_name          = data.azurerm_resource_group.dr_resource_group.name
  virtual_network_name         = data.azurerm_virtual_network.dr_vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Peering from Hub dr
resource "azurerm_virtual_network_peering" "hub_to_dr_peering" {
  name                         = "${var.hub_vnet_name}-to-${var.dr_vnet_name}-peering"
  resource_group_name          = data.azurerm_resource_group.hub_resource_group.name
  virtual_network_name         = data.azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.dr_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

###################################################################
###################################################################
##### UPDATE Private DNS Hosted Zone Created with the Cluster #####
###################################################################
###################################################################

data "azurerm_private_dns_zone" "primary_private_dns" {
  name                = var.primary_private_dns_domain
  resource_group_name = data.azurerm_resource_group.primary_resource_group.name
}

data "azurerm_private_dns_zone" "dr_private_dns" {
  name                = var.dr_private_dns_domain
  resource_group_name = data.azurerm_resource_group.dr_resource_group.name
}

## LINK TO SPOKE 1 vNET
resource "azurerm_private_dns_zone_virtual_network_link" "primary_dns_link" {
  name                  = data.azurerm_virtual_network.hub_vnet.name
  private_dns_zone_name = data.azurerm_private_dns_zone.primary_private_dns.name
  resource_group_name   = data.azurerm_resource_group.primary_resource_group.name
  virtual_network_id    = data.azurerm_virtual_network.hub_vnet.id

  # Optional: Set to `true` to enable auto-registration of DNS records (only one)
  registration_enabled = false
}

## LINK TO SPOKE 2 vNET
resource "azurerm_private_dns_zone_virtual_network_link" "dr_dns_link" {
  name                  = data.azurerm_virtual_network.hub_vnet.name
  private_dns_zone_name = data.azurerm_private_dns_zone.dr_private_dns.name
  resource_group_name   = data.azurerm_resource_group.dr_resource_group.name
  virtual_network_id    = data.azurerm_virtual_network.hub_vnet.id

  # Optional: Set to `true` to enable auto-registration of DNS records (only one)
  registration_enabled = false
}
