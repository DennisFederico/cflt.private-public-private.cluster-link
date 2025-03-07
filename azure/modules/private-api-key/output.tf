output "access_data" {
    value = <<-EOT
    KAFKA Cluster: ${var.kafka_cluster.display_name} (${var.kafka_cluster.id})
        Bootstrap: ${var.kafka_cluster.bootstrap_endpoint}
         Endpoint: ${var.kafka_cluster.rest_endpoint}

    Cluster Owner: ${confluent_service_account.cluster_owner.display_name} (${confluent_service_account.cluster_owner.id})
         API-KEY: ${confluent_api_key.cluster_owner_api_key.id} : ${nonsensitive(confluent_api_key.cluster_owner_api_key.secret)}

    EOT
    sensitive = false
}
