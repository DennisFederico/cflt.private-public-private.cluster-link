output "cluster" {
    value = confluent_kafka_cluster.kafka_cluster
}

output "owner" {
    value = confluent_service_account.cluster_owner
}

output "api_key" {
    value = confluent_api_key.cluster_owner_api_key
}

output "resources" {
    value = <<-EOT
    Environment: ${var.cflt_environment.display_name} (${var.cflt_environment.id})
    
    KAFKA Cluster: ${confluent_kafka_cluster.kafka_cluster.display_name} (${confluent_kafka_cluster.kafka_cluster.id})
        Bootstrap: ${confluent_kafka_cluster.kafka_cluster.bootstrap_endpoint}
         Endpoint: ${confluent_kafka_cluster.kafka_cluster.rest_endpoint}

    Cluster Owner: ${confluent_service_account.cluster_owner.display_name} (${confluent_service_account.cluster_owner.id})
          API-KEY: ${confluent_api_key.cluster_owner_api_key.id} : ${nonsensitive(confluent_api_key.cluster_owner_api_key.secret)}

    EOT
    sensitive = false
}