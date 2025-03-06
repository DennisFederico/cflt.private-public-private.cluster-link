data "confluent_environment" "environment" {
  display_name = var.environment_name
}

resource "confluent_network" "private_service_connect" {
  display_name     = var.kafka_network_name
  cloud            = var.cc_provider
  region           = var.cc_provider_region
  connection_types = ["PRIVATELINK"]
  zones            = keys(var.subnet_name_by_zone)
  environment {
    id = data.confluent_environment.environment.id
  }
  dns_config {
    resolution = "PRIVATE"
  }
}

resource "confluent_private_link_access" "gcp" {
  display_name = "GCP Private Service Connect"
  gcp {
    project = var.gcp_project_id
  }
  environment {
    id = data.confluent_environment.environment.id
  }
  network {
    id = confluent_network.private_service_connect.id
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
  
  network {
    id = confluent_network.private_service_connect.id
  }
}

## Service Account for the cluster
resource "confluent_service_account" "cluster_owner" {
  display_name = "${confluent_kafka_cluster.kafka_cluster.display_name}_SA"
  description  = "${confluent_kafka_cluster.kafka_cluster.display_name} Service Account that owns the cluster"
}

resource "confluent_role_binding" "kafka_cluser_owner_rb" {
  principal   = "User:${confluent_service_account.cluster_owner.id}"
  role_name   = "CloudClusterAdmin"  
  crn_pattern = confluent_kafka_cluster.kafka_cluster.rbac_crn
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

  # The goal is to ensure that
  # 1. confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic resources.
  # 2. Kafka connectivity through GCP Private Service Connect is setup.
  depends_on = [
    confluent_role_binding.kafka_cluser_owner_rb,
    confluent_private_link_access.gcp,
    
    google_compute_forwarding_rule.psc_endpoint_ilb,
    google_dns_record_set.psc_endpoint_rs,
    google_dns_record_set.psc_endpoint_zonal_rs,
    google_compute_firewall.allow-https-kafka,
  ]

}

locals {
  dns_domain = confluent_network.private_service_connect.dns_domain
  network_id  = split(".", local.dns_domain)[0]
}

data "google_compute_network" "psc_endpoint_network" {
  name = var.gcp_vpc_network
}

data "google_compute_subnetwork" "psc_endpoint_subnetwork" {
  name = var.gcp_subnetwork_name
}

# resource "google_compute_subnetwork" "psc_endpoint_subnetwork" {
#   name          = var.gcp_subnetwork_name
#   ip_cidr_range = "10.20.0.0/16"
#   region        = var.cc_provider_region
#   network       = data.google_compute_network.psc_endpoint_network.id
# }

resource "google_compute_address" "psc_endpoint_ip" {
  for_each = var.subnet_name_by_zone

  name         = "ccloud-endpoint-ip-${local.network_id}-${each.key}"
  subnetwork   = var.gcp_subnetwork_name
  address_type = "INTERNAL"
}

# Private Service Connect endpoint
resource "google_compute_forwarding_rule" "psc_endpoint_ilb" {
  for_each = var.subnet_name_by_zone

  name = "ccloud-endpoint-${local.network_id}-${each.key}"

  target                = lookup(confluent_network.private_service_connect.gcp[0].private_service_connect_service_attachments, each.key, "\n\nerror: ${each.key} subnet is missing from CCN's Private Service Connect service attachments")
  load_balancing_scheme = "" # need to override EXTERNAL default when target is a service attachment
  network               = var.gcp_vpc_network
  ip_address            = google_compute_address.psc_endpoint_ip[each.key].id
}

# Private hosted zone for Private Service Connect endpoints
resource "google_dns_managed_zone" "psc_endpoint_hz" {
  name     = "ccloud-endpoint-zone-${local.network_id}"
  dns_name = "${local.dns_domain}."

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.psc_endpoint_network.id
    }
  }
}

resource "google_dns_record_set" "psc_endpoint_rs" {
  name = "*.${google_dns_managed_zone.psc_endpoint_hz.dns_name}"
  type = "A"
  ttl  = 60

  managed_zone = google_dns_managed_zone.psc_endpoint_hz.name
  rrdatas = [
    for zone, _ in var.subnet_name_by_zone : google_compute_address.psc_endpoint_ip[zone].address
  ]
}

resource "google_dns_record_set" "psc_endpoint_zonal_rs" {
  for_each = var.subnet_name_by_zone

  name = "*.${each.key}.${google_dns_managed_zone.psc_endpoint_hz.dns_name}"
  type = "A"
  ttl  = 60

  managed_zone = google_dns_managed_zone.psc_endpoint_hz.name
  rrdatas      = [google_compute_address.psc_endpoint_ip[each.key].address]
}

resource "google_compute_firewall" "allow-https-kafka" {
  name    = "ccloud-endpoint-firewall-${local.network_id}"
  network = data.google_compute_network.psc_endpoint_network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "9092"]
  }

  direction          = "EGRESS"
  destination_ranges = [data.google_compute_subnetwork.psc_endpoint_subnetwork.ip_cidr_range]
}