terraform {
  required_providers {
    confluent = {
      source = "confluentinc/confluent"
      version = "2.7.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.18.0"
    }
  }
}

provider "confluent" {
  # cloud_api_key    =  # optionally use CONFLUENT_CLOUD_API_KEY env var
  # cloud_api_secret =  # optionally use CONFLUENT_CLOUD_API_SECRET env var
}

# Set GOOGLE_APPLICATION_CREDENTIALS environment variable to a path to a key file
# for Google TF Provider to work: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials
provider "google" {
  project = var.gcp_project_id
  region  = var.cc_provider_region_dr
}

module "jump_cluster" {
  source = "./modules/cluster"

  environment_name = var.environment_name
  kafka_cluster_name = var.kafka_cluster_name_jump
  kafka_cluster_type = var.kafka_cluster_type_jump
  dedicated_cku = var.dedicated_cku
  cc_provider = var.cc_provider
  cc_provider_region = var.cc_provider_region_jump
}

module "gcp_private_primary" {
  source = "./modules/gcp-private"

  gcp_project_id = var.gcp_project_id
  gcp_vpc_network = var.gcp_vpc_network
  gcp_subnetwork_name = var.gcp_subnetwork_name_primary
  subnet_name_by_zone = var.gcp_subnet_name_by_zone_primary
  environment_name = var.environment_name
  kafka_network_name = var.kafka_network_name_primary
  kafka_cluster_name = var.kafka_cluster_name_primary
  kafka_cluster_type = var.kafka_cluster_type_primary
  cc_provider = var.cc_provider
  cc_provider_region = var.cc_provider_region_primary
}

module "gcp_private_dr" {
  source = "./modules/gcp-private"

  gcp_project_id = var.gcp_project_id
  gcp_vpc_network = var.gcp_vpc_network
  gcp_subnetwork_name = var.gcp_subnetwork_name_dr
  subnet_name_by_zone = var.gcp_subnet_name_by_zone_dr
  environment_name = var.environment_name
  kafka_network_name = var.kafka_network_name_dr
  kafka_cluster_name = var.kafka_cluster_name_dr
  kafka_cluster_type = var.kafka_cluster_type_dr
  cc_provider = var.cc_provider
  cc_provider_region = var.cc_provider_region_dr
}