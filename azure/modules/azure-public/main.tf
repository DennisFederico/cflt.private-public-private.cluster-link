resource "confluent_kafka_cluster" "kafka_cluster" {
  display_name = var.kafka_cluster_name
  availability = "SINGLE_ZONE"
  cloud        = var.cc_provider
  region       =  var.cc_provider_region
  
  dynamic "basic" {
    for_each = var.kafka_cluster_type == "BASIC" ? [1] : []
    content {
      
    }
  }

  dynamic "standard" {
    for_each = var.kafka_cluster_type == "STANDARD" ? [1] : []
    content {

    }
  }

  dynamic "dedicated" {
    for_each = var.kafka_cluster_type == "DEDICATED" ? [1] : []
    content {
      cku = var.dedicated_cku
    }
  }

  environment {
    id = var.cflt_environment.id
  }
}

## Service Account for the cluster
resource "confluent_service_account" "cluster_owner" {
  display_name = "${confluent_kafka_cluster.kafka_cluster.display_name}_SA"
  description  = "${confluent_kafka_cluster.kafka_cluster.display_name} Service Account that owns the cluster"
}

resource "confluent_api_key" "cluster_owner_api_key" {
  display_name = "${confluent_service_account.cluster_owner.display_name}_API_KEY"
  description  = "Kafka API Key that is owned by '${confluent_service_account.cluster_owner.display_name}' service account"

  owner {
    id          = confluent_service_account.cluster_owner.id
    api_version = confluent_service_account.cluster_owner.api_version
    kind        = confluent_service_account.cluster_owner.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.kafka_cluster.id
    api_version = confluent_kafka_cluster.kafka_cluster.api_version
    kind        = confluent_kafka_cluster.kafka_cluster.kind

    environment {
      id = var.cflt_environment.id
    }
  }
}

resource "confluent_role_binding" "kafka_cluser_owner_rb" {
  principal   = "User:${confluent_service_account.cluster_owner.id}"
  role_name   = "CloudClusterAdmin"  
  crn_pattern = confluent_kafka_cluster.kafka_cluster.rbac_crn
}