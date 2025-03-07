variable "primary_region" {  
  type        = string
  default = "germanywestcentral"
}

variable "dr_region" {
    type        = string
    default = "italynorth"
}

variable "azure_subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "azure_resource_group_prefix" {
  description = "The name of the Azure Resource Group that the virtual network belongs to"
  type        = string
}
