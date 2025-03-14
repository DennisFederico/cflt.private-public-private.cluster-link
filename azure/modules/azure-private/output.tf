output "resources" {
    value = <<-EOT
    Environment: ${var.cflt_environment.display_name} (${var.cflt_environment.id})
    
    KAFKA Cluster: ${confluent_kafka_cluster.kafka_cluster.display_name} (${confluent_kafka_cluster.kafka_cluster.id})
        Bootstrap: ${confluent_kafka_cluster.kafka_cluster.bootstrap_endpoint}
         Endpoint: ${confluent_kafka_cluster.kafka_cluster.rest_endpoint}


    EOT
    sensitive = false
}

output "dns-domain" {
    value = confluent_network.privatelink.dns_domain
}

output "kafka_cluster" {
    value = confluent_kafka_cluster.kafka_cluster
}

output "resource_group" {
    value = module.privatelink.resource_group
}