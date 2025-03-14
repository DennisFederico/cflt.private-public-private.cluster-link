variable "create_private_cluster_api_keys" {
  description = "Create API keys for the PRIVATE Kafka clusters"
  type    = bool
  default = false
}

variable "primary_region" {  
  type        = string
  default = "germanywestcentral"
}

variable "dr_region" {
    type        = string
    default = "italynorth"
}

variable "azure_subscription_id" {
  description = "The Azure subscription ID. Better set as environment variable TF_VAR_azure_subscription_id"
  type        = string
}

variable "azure_hub_resource_name" {
  description = "This is also used as prefix for the regional resource groups created for each private cluster"
  type        = string
}

variable "public_jump_cluster_name" {
  default = "public-jump-cluster"
}

variable "private_primary_cluster_name" {
  default = "private-primary-cluster"
}

variable "private_dr_cluster_name" {
  default = "private-dr-cluster"
}

variable "azure_primary_vnet_cidr" {
  default = "20.1.0.0/16"
}

variable "azure_primary_default_subnet_cidr" {
  default = "20.1.1.0/24"
}

variable "azure_dr_vnet_cidr" {
  default = "30.1.0.0/16"
}

variable "azure_dr_default_subnet_cidr" {
  default = "30.1.1.0/24"
}

variable "proxy_allowed_cidrs" {
  default = ["170.253.50.253/32"]
}
