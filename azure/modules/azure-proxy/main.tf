# Create a new resource group if needed
data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

# Create a new virtual network
data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

data "azurerm_subnet" "default_subnet" {
  name                 = "default"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_linux_virtual_machine" "cc_proxy_vm" {
  name                = "cc-proxy-vm"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location

  size           = var.vm_size
  admin_username = "ccproxyadmin"

  network_interface_ids = [azurerm_network_interface.cc_proxy_vm_nic.id]

  admin_ssh_key {
    username   = "ccproxyadmin"
    public_key = file("${path.module}/id_rsa_jump.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "Debian-11"
    sku       = "11-backports-gen2"
    version   = "latest"
  }

  custom_data = filebase64("${path.module}/nginx-install.yml")
}

resource "azurerm_public_ip" "cc_proxy_vm_public_nic" {
  name                = "cc-proxy-vm-public-ip"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  sku                 = "Basic"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "cc_proxy_vm_nic" {
  name                = "cc_proxy_vm_nic"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location

  ip_configuration {
    name                          = "cc_proxy_vm-ip"
    subnet_id                     = data.azurerm_subnet.default_subnet.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.cc_proxy_vm_public_nic.id
  }

  depends_on = [ azurerm_public_ip.cc_proxy_vm_public_nic ]
}

resource "azurerm_network_security_group" "cc_proxy_vm_nsg" {
  name                = "cc_proxy-nsg"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
}

resource "azurerm_network_security_rule" "allow_cc_proxy_https" {
  network_security_group_name = azurerm_network_security_group.cc_proxy_vm_nsg.name
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  name                        = "allow-cc_proxy-https"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = var.allowed_cidrs
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "allow_cc_proxy_kafka" {
  network_security_group_name = azurerm_network_security_group.cc_proxy_vm_nsg.name
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  name                        = "allow-cc_proxy-kafka"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9092"
  source_address_prefixes     = var.allowed_cidrs
  destination_address_prefix  = "*"
}


resource "azurerm_network_interface_security_group_association" "cc_proxy_vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.cc_proxy_vm_nic.id
  network_security_group_id = azurerm_network_security_group.cc_proxy_vm_nsg.id
}
