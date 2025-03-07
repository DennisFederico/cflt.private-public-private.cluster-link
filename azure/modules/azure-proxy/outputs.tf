output "cc_proxy_public_ip" {
  value = azurerm_public_ip.cc_proxy_vm_public_nic.ip_address
}