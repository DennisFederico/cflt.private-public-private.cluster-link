variable "gcp_project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "gcp_vpc_network" {
  description = "The VPC network name to provision Private Service Connect endpoint to Confluent Cloud"
  type        = string
}

variable "gcp_subnetwork_name" {
  description = "The subnetwork name to provision Private Service Connect endpoint to Confluent Cloud"
  type        = string
}

variable "subnet_name_by_zone" {
  description = "A map of Zone to Subnet Name"
  type        = map(string)
}

variable environment_name {
    description = "The name of the environment to create"
    type        = string
}

variable "kafka_network_name" {
    type = string
}


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
    default = "GCP" 
}

variable "cc_provider_region" {
    type = string
}

