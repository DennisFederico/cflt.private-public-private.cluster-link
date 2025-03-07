variable "hub_resource_group_name" {
  description = "The resource group of the existing virtual network to peer with"
}

variable "primary_resource_group_name" {
  description = "The name of the resource group for the new virtual network"
}

variable "dr_resource_group_name" {
  description = "The name of the resource group for the new virtual network"
}

variable "hub_vnet_name" {
  description = "The name of the existing virtual network to peer with"
}

variable "primary_vnet_name" {
  description = "The name of the new virtual network"
}

variable "dr_vnet_name" {
  description = "The name of the new virtual network"
}

# variable "primary_vnet_cidr" {
#   description = "The CIDR of the new vNet (should not overlap with the exiting vNet to peer with)"
# }

# variable "dr_vnet_cidr" {
#   description = "The CIDR of the subnet to create on the new vNet"
# }

# variable "primary_default_subnet_cidr" {
#   description = "The CIDR of the new vNet (should not overlap with the exiting vNet to peer with)"
# }

# variable "dr_default_subnet_cidr" {
#   description = "The CIDR of the subnet to create on the new vNet"
# }

variable "primary_private_dns_domain" {
  description = "The name of the Private DNS on the vNet attached to the primary cluster"
}

variable "dr_private_dns_domain" {
  description = "The name of the Private DNS on the vNet attached to the dr cluster"
}

# variable "external_ip" {
#   description = "An external IP for the optional firewall rules"
# }
