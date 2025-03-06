variable environment_name {
    description = "The name of the environment to create"
    type        = string
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
    default = "AWS" 
}

variable "cc_provider_region" {
    type = string
}

