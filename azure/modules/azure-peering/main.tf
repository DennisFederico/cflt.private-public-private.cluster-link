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

##################################################################
##################################################################
### (OPTIONAL) Creating a VM on each vNet to test connectivity ###
##################################################################
##################################################################

# #### VM on HUB vNet ####
# # Create a VM in the existing virtual network
# resource "azurerm_linux_virtual_machine" "hub_vm" {
#   name                = "hubVM"
#   resource_group_name = data.azurerm_resource_group.hub_resource_group.name
#   location            = data.azurerm_resource_group.hub_resource_group.location
#   size                = "Standard_DS1_v2"
#   admin_username      = "dfederico"
#   network_interface_ids = [
#     azurerm_network_interface.hub_nic.id,
#   ]
#   admin_ssh_key {
#     username   = "dfederico"
#     public_key = file("~/.ssh/id_rsa_jump.pub")
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Debian"
#     offer     = "Debian-11"
#     sku       = "11-backports-gen2"
#     version   = "latest"
#   }
# }

# data "azurerm_subnet" "hub_default_subnet" {
#   name                 = "default"
#   virtual_network_name = data.azurerm_virtual_network.hub_vnet.name
#   resource_group_name  = data.azurerm_resource_group.hub_resource_group.name
# }

# # Create a network interface for the existing VM
# resource "azurerm_network_interface" "hub_nic" {
#   name                = "hubVM-nic"
#   resource_group_name = data.azurerm_resource_group.hub_resource_group.name
#   location            = data.azurerm_resource_group.hub_resource_group.location

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = data.azurerm_subnet.hub_default_subnet.id
#     private_ip_address_allocation = "Dynamic"

#     # (OPTIONAL) Associate the public IP
#     # public_ip_address_id = azurerm_public_ip.hub_vm_public_ip.id
#   }
# }

# # (OPTIONAL) Create a public IP for the HUB VM
# # resource "azurerm_public_ip" "hub_vm_public_ip" {
# #   name                = "hubVM-public-ip"
# #   resource_group_name = data.azurerm_resource_group.existing_resource_group.name
# #   location            = data.azurerm_resource_group.existing_resource_group.location
# #   sky                 = "Basic"
# #   allocation_method   = "Dynamic"
# # }


# #### VM on SPOKE vNet ####
# # Create a VM in the new virtual network
# resource "azurerm_linux_virtual_machine" "primary_vm" {
#   name                = "primaryVM"
#   resource_group_name = data.azurerm_resource_group.primary_resource_group.name
#   location            = data.azurerm_resource_group.primary_resource_group.location
#   size                = "Standard_DS1_v2"
#   admin_username      = "dfederico"

#   network_interface_ids = [
#     azurerm_network_interface.primary_nic.id,
#   ]

#   admin_ssh_key {
#     username   = "dfederico"
#     public_key = file("~/.ssh/id_rsa_jump.pub")
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Debian"
#     offer     = "Debian-11"
#     sku       = "11-backports-gen2"
#     version   = "latest"
#   }
# }

# data "azurerm_subnet" "primary_default_subnet" {
#   name                 = "default"
#   virtual_network_name = azurerm_virtual_network.primary_vnet.name
#   resource_group_name  = data.azurerm_resource_group.primary_resource_group.name

#   depends_on = [azurerm_virtual_network.primary_vnet]
# }

# # # (OPTIONAL) Create a public IP for the spoke VM
# # resource "azurerm_public_ip" "primary_vm_public_ip" {
# #   name                = "primaryVM-public-ip"
# #   resource_group_name = data.azurerm_resource_group.primary_resource_group.name
# #   location            = data.azurerm_resource_group.primary_resource_group.location
# #   sky                 = "Basic"
# #   allocation_method   = "Dynamic"
# # }

# # Create a network interface for the SPOKE VM
# resource "azurerm_network_interface" "primary_nic" {
#   name                = "spokeVM-nic"
#   resource_group_name = data.azurerm_resource_group.primary_resource_group.name
#   location            = data.azurerm_resource_group.primary_resource_group.location

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = data.azurerm_subnet.primary_default_subnet.id
#     private_ip_address_allocation = "Dynamic"

#     # # (OPTIONAL) Associate the public IP
#     # public_ip_address_id = azurerm_public_ip.primary_vm_public_ip.id
#   }
# }

# #### VM on dr vNet ####
# # Create a VM in the existing virtual network (dr)
# resource "azurerm_linux_virtual_machine" "dr_vm" {
#   name                = "drVM"
#   resource_group_name = data.azurerm_resource_group.dr.name
#   location            = data.azurerm_resource_group.dr.location
#   size                = "Standard_DS1_v2"
#   admin_username      = "dfederico"
#   network_interface_ids = [
#     azurerm_network_interface.dr_nic.id,
#   ]
#   admin_ssh_key {
#     username   = "dfederico"
#     public_key = file("~/.ssh/id_rsa_jump.pub")
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Debian"
#     offer     = "Debian-11"
#     sku       = "11-backports-gen2"
#     version   = "latest"
#   }
# }

# data "azurerm_subnet" "dr_default_subnet" {
#   name                 = "default"
#   virtual_network_name = azurerm_virtual_network.dr_vnet.name
#   resource_group_name  = data.azurerm_resource_group.dr.name

#   depends_on = [azurerm_virtual_network.dr_vnet]
# }

# # Create a network interface for the existing VM
# resource "azurerm_network_interface" "dr_nic" {
#   name                = "drVM-nic"
#   resource_group_name = data.azurerm_resource_group.dr.name
#   location            = data.azurerm_resource_group.dr.location

#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = data.azurerm_subnet.dr_default_subnet.id
#     private_ip_address_allocation = "Dynamic"

#     # (OPTIONAL) Associate the public IP
#     # public_ip_address_id = azurerm_public_ip.dr_vm_public_ip.id
#   }
# }

# # # (OPTIONAL) Create a public IP for the spoke VM
# # resource "azurerm_public_ip" "dr_vm_public_ip" {
# #   name                = "drVM-public-ip"
# #   resource_group_name = data.azurerm_resource_group.dr.name
# #   location            = data.azurerm_resource_group.dr.location
# #   sky                 = "Basic"
# #   allocation_method   = "Dynamic"
# # }



###################################################################
###################################################################
### (OPTIONAL) Firewall for external SSH - Use only for testing ###
###################################################################
###################################################################

# resource "azurerm_network_security_group" "hub_vm_nsg" {
#   name                = "hub-nsg"
#   resource_group_name = data.azurerm_resource_group.hub_resource_group.name
#   location            = data.azurerm_resource_group.hub_resource_group.location
# }

# resource "azurerm_network_security_rule" "allow_ssh_hub" {
#   network_security_group_name = azurerm_network_security_group.hub_vm_nsg.name
#   resource_group_name         = data.azurerm_resource_group.hub_resource_group.name
#   name                        = "allow-ssh"
#   priority                    = 1000
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "22"
#   source_address_prefixes     = [var.external_ip, "10.0.0.0/8", var.primary_vnet_cidr, var.dr_vnet_cidr]
#   destination_address_prefix  = "*"
# }

# resource "azurerm_network_security_rule" "allow_ping_hub" {
#   network_security_group_name = azurerm_network_security_group.hub_vm_nsg.name
#   resource_group_name         = data.azurerm_resource_group.hub_resource_group.name
#   name                        = "allow-Ping"
#   priority                    = 110
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Icmp"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
# }

# resource "azurerm_network_security_group" "primary_vm_nsg" {
#   name                = "primary-nsg"
#   resource_group_name = data.azurerm_resource_group.primary_resource_group.name
#   location            = data.azurerm_resource_group.primary_resource_group.location
# }

# resource "azurerm_network_security_rule" "allow_ssh_primary" {
#   network_security_group_name = azurerm_network_security_group.primary_vm_nsg.name
#   resource_group_name         = data.azurerm_resource_group.primary_resource_group.name
#   name                        = "allow-ssh"
#   priority                    = 1000
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "22"
#   source_address_prefixes     = [var.external_ip, "10.0.0.0/8"]
#   destination_address_prefix  = "*"
# }

# resource "azurerm_network_security_rule" "allow_ping_primary" {
#   network_security_group_name = azurerm_network_security_group.primary_vm_nsg.name
#   resource_group_name         = data.azurerm_resource_group.primary_resource_group.name
#   name                        = "allow-Ping"
#   priority                    = 110
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Icmp"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
# }

# resource "azurerm_network_security_group" "dr_vm_nsg" {
#   name                = "dr-nsg"
#   resource_group_name = data.azurerm_resource_group.dr.name
#   location            = data.azurerm_resource_group.dr.location
# }

# resource "azurerm_network_security_rule" "allow_ssh_dr" {
#   network_security_group_name = azurerm_network_security_group.dr_vm_nsg.name
#   resource_group_name         = data.azurerm_resource_group.dr.name
#   name                        = "allow-ssh"
#   priority                    = 1000
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "22"
#   source_address_prefixes     = [var.external_ip, "10.0.0.0/8"]
#   destination_address_prefix  = "*"
# }

# resource "azurerm_network_security_rule" "allow_ping_dr" {
#   network_security_group_name = azurerm_network_security_group.dr_vm_nsg.name
#   resource_group_name         = data.azurerm_resource_group.dr.name
#   name                        = "allow-Ping"
#   priority                    = 110
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Icmp"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
# }

