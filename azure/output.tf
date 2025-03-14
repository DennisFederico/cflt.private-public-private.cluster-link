output "summary" {
    value = <<-EOT

    -----
    Confluent Cloud Environment: ${confluent_environment.main.display_name} (${confluent_environment.main.id})
    
    -----

    Jump Public Cluster: "${module.jump_cluster.cluster.display_name}" (${module.jump_cluster.cluster.id})
    Bootstrap: ${module.jump_cluster.cluster.bootstrap_endpoint}
    Endpoint: ${module.jump_cluster.cluster.rest_endpoint}
    
    Cluster Owner: ${module.jump_cluster.owner.display_name} (${module.jump_cluster.owner.id})
    API-KEY: ${module.jump_cluster.api_key.id} : ${nonsensitive(module.jump_cluster.api_key.secret)}

    -----

    Primary Private Cluster: "${module.primary_cluster.kafka_cluster.display_name}" (${module.primary_cluster.kafka_cluster.id})
    Bootstrap: ${module.primary_cluster.kafka_cluster.bootstrap_endpoint}
    Endpoint: ${module.primary_cluster.kafka_cluster.rest_endpoint}

    Cluster Owner: ${module.primary_apikey.cluster_owner.display_name} (${module.primary_apikey.cluster_owner.id})
    API-KEY: "${var.create_private_cluster_api_keys ? "${module.primary_apikey.api_key[0].id} ${nonsensitive(module.primary_apikey.api_key[0].secret)}" : "To create API KEYS for Private Clusters, run TF using -var=\"create_private_cluster_api_keys=true\"."}"

    -----

    DR Private Cluster: "${module.dr_cluster.kafka_cluster.display_name}" (${module.dr_cluster.kafka_cluster.id})
    Bootstrap: ${module.dr_cluster.kafka_cluster.bootstrap_endpoint}
    Endpoint: ${module.dr_cluster.kafka_cluster.rest_endpoint}

    Cluster Owner: ${module.dr_apikey.cluster_owner.display_name} (${module.dr_apikey.cluster_owner.id})
    API-KEY: "${var.create_private_cluster_api_keys ? "${module.dr_apikey.api_key[0].id} ${nonsensitive(module.dr_apikey.api_key[0].secret)}" : "To create API KEYS for Private Clusters, run TF using -var=\"create_private_cluster_api_keys=true\"."}"
    -----
    EOT

    sensitive = false
}

output "proxy_data" {
    value = <<-EOT
    Primary DNS: "${module.primary_cluster.dns-domain}"
    DR DNS: "${module.dr_cluster.dns-domain}"
    PROXY Public IP: "${module.cc_proxy.cc_proxy_public_ip}"
    EOT

    sensitive = false
}

output "exports" {
    value = <<-EOT
    
    ${var.create_private_cluster_api_keys ? "" : "IMPORTANT: To create API KEYS for Private Clusters, run TF using -var=\"create_private_cluster_api_keys=true\"."}
    -----
    export CFLT_ENVIRONMENT_ID="${confluent_environment.main.id}"
    
    export JUMP_CLUSTER_ID="${module.jump_cluster.cluster.id}"
    export JUMP_CLUSTER_BOOTSTRAP="${module.jump_cluster.cluster.bootstrap_endpoint}"
    export JUMP_CLUSTER_REST="${module.jump_cluster.cluster.rest_endpoint}"
    export JUMP_API_KEY="${module.jump_cluster.api_key.id}"
    export JUMP_API_SECRET="${nonsensitive(module.jump_cluster.api_key.secret)}"

    export PRIMARY_CLUSTER_ID="${module.primary_cluster.kafka_cluster.id}"
    export PRIMARY_CLUSTER_BOOTSTRAP="${module.primary_cluster.kafka_cluster.bootstrap_endpoint}"
    export PRIMARY_CLUSTER_REST="${module.primary_cluster.kafka_cluster.rest_endpoint}"
    export PRIMARY_API_KEY="${var.create_private_cluster_api_keys ? module.primary_apikey.api_key[0].id : ""}"
    export PRIMARY_API_SECRET="${var.create_private_cluster_api_keys ? nonsensitive(module.primary_apikey.api_key[0].secret) : ""}"

    export DR_CLUSTER_ID="${module.dr_cluster.kafka_cluster.id}"
    export DR_CLUSTER_BOOTSTRAP="${module.dr_cluster.kafka_cluster.bootstrap_endpoint}"
    export DR_CLUSTER_REST="${module.dr_cluster.kafka_cluster.rest_endpoint}"
    export DR_API_KEY="${var.create_private_cluster_api_keys ? module.dr_apikey.api_key[0].id : ""}"
    export DR_API_SECRET="${var.create_private_cluster_api_keys ? nonsensitive(module.dr_apikey.api_key[0].secret) : ""}"

    -----
    EOT

    sensitive = false
}
