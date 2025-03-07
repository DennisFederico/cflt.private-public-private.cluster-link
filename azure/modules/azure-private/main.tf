resource "confluent_network" "privatelink" {
  display_name     = "${var.kafka_cluster_name} Private Link Network"
  cloud            = "AZURE"
  region           = var.cc_provider_region
  connection_types = ["PRIVATELINK"]
  environment {
    id = var.cflt_environment.id
  }

  dns_config {
    resolution = "PRIVATE"
  }
}

resource "confluent_private_link_access" "main" {
  display_name = "${var.kafka_cluster_name} Azure Private Link Access"
  azure {
    subscription = var.azure_subscription_id
  }
  environment {
    id = var.cflt_environment.id
  }
  network {
    id = confluent_network.privatelink.id
  }
}

resource "confluent_kafka_cluster" "kafka_cluster" {
  display_name = var.kafka_cluster_name
  availability = "SINGLE_ZONE"
  cloud        = confluent_network.privatelink.cloud
  region       = var.cc_provider_region
  
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

  network {
    id = confluent_network.privatelink.id
  }
}

module "privatelink" {
  source                        = "../azure-privatelink"
  resource_group                = var.resource_group
  vnet_region                   = var.cc_provider_region
  vnet_name                     = var.vnet_name
  dns_domain                    = confluent_network.privatelink.dns_domain
  private_link_service_aliases  = confluent_network.privatelink.azure[0].private_link_service_aliases
  subnet_name_by_zone           = var.subnet_name_by_zone
  vnet_cidr                     = var.vnet_cidr
  default_subnet_cidr           = var.default_subnet_cidr
}
