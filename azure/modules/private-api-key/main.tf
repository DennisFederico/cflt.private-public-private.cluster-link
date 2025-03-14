## Service Account for the cluster
resource "confluent_service_account" "cluster_owner" {
  display_name = "${var.kafka_cluster.display_name}_SA"
  description  = "${var.kafka_cluster.display_name} Service Account that owns the cluster"
}

resource "confluent_role_binding" "kafka_cluser_owner_rb" {
  principal   = "User:${confluent_service_account.cluster_owner.id}"
  role_name   = "CloudClusterAdmin"  
  crn_pattern = var.kafka_cluster.rbac_crn
}

resource "confluent_api_key" "cluster_owner_api_key" {
  count = var.create_api_keys ? 1 : 0

  display_name = "${confluent_service_account.cluster_owner.display_name}_API_KEY"
  description  = "Kafka API Key that is owned by '${confluent_service_account.cluster_owner.display_name}' service account"

  owner {
    id          = confluent_service_account.cluster_owner.id
    api_version = confluent_service_account.cluster_owner.api_version
    kind        = confluent_service_account.cluster_owner.kind
  }

  managed_resource {
    id          = var.kafka_cluster.id
    api_version = var.kafka_cluster.api_version
    kind        = var.kafka_cluster.kind

    environment {
      id = var.cflt_environment.id
    }
  }

  depends_on = [
    confluent_role_binding.kafka_cluser_owner_rb,
    confluent_service_account.cluster_owner,
  ]
}
