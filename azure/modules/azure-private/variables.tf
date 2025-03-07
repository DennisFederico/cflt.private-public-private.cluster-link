variable cflt_environment {
    description = "The Confluent Environment resource"
    type        = any
}

# variable cflt_private_network {
#     description = "The Confluent Private Link Network"
#     type        = any
# }

variable "kafka_cluster_name" {
    type = string
}

variable "kafka_cluster_type" {
    type = string
    description = "The type of Kafka cluster to create"
    validation {
        condition     = can(regex("^(BASIC|STANDARD|DEDICATED)$", var.kafka_cluster_type))
        error_message = "Kafka Cluster type can be either BASIC, STANDARD or DEDICATED. Received: ${var.kafka_cluster_type}."
    }
    default = "BASIC" 
}

variable "dedicated_cku" {
    type = number
    description = "Dedicated Cluster Kafka Units"
    default = 1
}

variable "cc_provider" {
    type = string
    description = "The cloud provider that will host the cluster"
    validation {
        condition     = can(regex("^(AWS|AZURE|GCP)$", var.cc_provider))
        error_message = "Allowed providers are AWS, AZURE or GCP. Received: ${var.cc_provider}."
    }
    default = "AWS" 
}

variable "cc_provider_region" {
    type = string
}

variable "azure_subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "resource_group" {
  description = "Resource group of the VNET"
  type        = string
}

variable "vnet_name" {
    type = string
}

variable "vnet_cidr" {
  description = "The CIDR of the new vNet (should not overlap with the exiting vNet to peer with)"
}

variable "default_subnet_cidr" {
  description = "The CIDR of the new vNet (should not overlap with the exiting vNet to peer with)"
}

variable "subnet_name_by_zone" {
  description = "A map of Zone to Subnet Name"
  type        = map(string)
}
