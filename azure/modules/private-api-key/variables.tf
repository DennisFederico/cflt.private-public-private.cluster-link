variable cflt_environment {
    description = "The Confluent Environment resource"
    type        = any
}

variable "kafka_cluster" {
    type        = any
}

variable "create_api_keys" {
    type        = bool
    default     = false
}
