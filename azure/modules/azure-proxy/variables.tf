variable "resource_group_name" {
  description = "The name of the resource group for the new virtual network"
}

variable "vnet_name" {
  description = "The name of the new virtual network to host the proxy"
}

variable "allowed_cidrs" {
  description = "An array of cidrs for firewall rules"
}

variable "vm_size" {
  description = "The type of vm to deploy"
  default = "Standard_B1ls"
}