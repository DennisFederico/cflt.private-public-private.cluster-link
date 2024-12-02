data "confluent_environment" "environment" {
  display_name = var.environment_name
  
  stream_governance {
    package = "ESSENTIALS"
  }
}

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
    id = data.confluent_environment.environment.id
  }
}

data "confluent_schema_registry_cluster" "schema_registry" {

  environment {
    id = data.confluent_environment.environment.id
  }

  depends_on = [ confluent_kafka_cluster.kafka_cluster ]

  # lifecycle {
  #   prevent_destroy = true
  # }
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
      id = data.confluent_environment.environment.id
    }
  }
}

resource "confluent_role_binding" "kafka_cluser_owner_rb" {
  principal   = "User:${confluent_service_account.cluster_owner.id}"
  role_name   = "CloudClusterAdmin"  
  crn_pattern = confluent_kafka_cluster.kafka_cluster.rbac_crn
}

# ##### SUPER "USER" - FOR BASIC CLUSTER (OR WHEN USING ACLs ONLY IN STANDARD)
# data "confluent_service_account" "super_user" {
#   id = "sa-nqknq6"
# }

# resource "confluent_api_key" "su_api_key" {
#   display_name = "${data.confluent_service_account.super_user.display_name}_API_KEY"
#   description  = "Kafka API Key that is owned by '${data.confluent_service_account.super_user.display_name}' service account"

#   owner {
#     id          = data.confluent_service_account.super_user.id
#     api_version = data.confluent_service_account.super_user.api_version
#     kind        = data.confluent_service_account.super_user.kind
#   }

#   managed_resource {
#     id          = confluent_kafka_cluster.kafka_cluster.id
#     api_version = confluent_kafka_cluster.kafka_cluster.api_version
#     kind        = confluent_kafka_cluster.kafka_cluster.kind

#     environment {
#       id = data.confluent_environment.environment.id
#     }
#   }
# }

# ## ACLS FOR CLUSTER OWNER
# resource "confluent_kafka_acl" "cluster_owner_acl_describe_topic_resource" {
#   kafka_cluster {
#     id = confluent_kafka_cluster.kafka_cluster.id
#   }
#   rest_endpoint = confluent_kafka_cluster.kafka_cluster.rest_endpoint

#   resource_type = "TOPIC"
#   resource_name = "*"
#   pattern_type  = "LITERAL"
#   principal     = "User:${confluent_service_account.cluster_owner.id}"
#   host          = "*"
#   operation     = "DESCRIBE"
#   permission    = "ALLOW"
  
#   credentials {
#     key    = confluent_api_key.su_api_key.id
#     secret = confluent_api_key.su_api_key.secret
#   }
# }

# resource "confluent_kafka_acl" "cluster_owner_acl_describe_config_topic_resource" {
#   kafka_cluster {
#     id = confluent_kafka_cluster.kafka_cluster.id
#   }
#   rest_endpoint = confluent_kafka_cluster.kafka_cluster.rest_endpoint

#   resource_type = "TOPIC"
#   resource_name = "*"
#   pattern_type  = "LITERAL"
#   principal     = "User:${confluent_service_account.cluster_owner.id}"
#   host          = "*"
#   operation     = "DESCRIBE_CONFIGS"
#   permission    = "ALLOW"
  
#   credentials {
#     key    = confluent_api_key.su_api_key.id
#     secret = confluent_api_key.su_api_key.secret
#   }
# }

# resource "confluent_kafka_acl" "cluster_owner_acl_create_topic_resource" {
#   kafka_cluster {
#     id = confluent_kafka_cluster.kafka_cluster.id
#   }
#   rest_endpoint = confluent_kafka_cluster.kafka_cluster.rest_endpoint

#   resource_type = "TOPIC"
#   resource_name = "*"
#   pattern_type  = "LITERAL"
#   principal     = "User:${confluent_service_account.cluster_owner.id}"
#   host          = "*"
#   operation     = "CREATE"
#   permission    = "ALLOW"
  
#   credentials {
#     key    = confluent_api_key.su_api_key.id
#     secret = confluent_api_key.su_api_key.secret
#   }
# }

# resource "confluent_kafka_acl" "cluster_owner_acl_create_topic" {
#   kafka_cluster {
#     id = confluent_kafka_cluster.kafka_cluster.id
#   }
#   rest_endpoint = confluent_kafka_cluster.kafka_cluster.rest_endpoint

#   resource_type = "CLUSTER"
#   resource_name = "kafka-cluster"
#   pattern_type  = "LITERAL"
#   principal     = "User:${confluent_service_account.cluster_owner.id}"
#   host          = "*"
#   operation     = "CREATE"
#   permission    = "ALLOW"
  
#   credentials {
#     key    = confluent_api_key.su_api_key.id
#     secret = confluent_api_key.su_api_key.secret
#   }
# }

# resource "confluent_kafka_acl" "cluster_owner_acl_create_acls" {
#   kafka_cluster {
#     id = confluent_kafka_cluster.kafka_cluster.id
#   }
#   rest_endpoint = confluent_kafka_cluster.kafka_cluster.rest_endpoint

#   resource_type = "CLUSTER"
#   resource_name = "kafka-cluster"
#   pattern_type  = "LITERAL"
#   principal     = "User:${confluent_service_account.cluster_owner.id}"
#   host          = "*"
#   operation     = "ALTER"
#   permission    = "ALLOW"
  
#   credentials {
#     key    = confluent_api_key.su_api_key.id
#     secret = confluent_api_key.su_api_key.secret
#   }
# }