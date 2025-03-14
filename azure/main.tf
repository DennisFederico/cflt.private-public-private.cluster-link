terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.12.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.15.0"
    }
  }
}

provider "confluent" {
  # cloud_api_key    =  # optionally use CONFLUENT_CLOUD_API_KEY env var
  # cloud_api_secret =  # optionally use CONFLUENT_CLOUD_API_SECRET env var
}

provider "azurerm" {
  features {
# See. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure
#
# Assuming a Service Principal with a Client Secret authentication, expose the following environment variables
# use ARM_CLIENT_ID env var
# use ARM_CLIENT_SECRET env var
# use ARM_TENANT_ID env var
# use ARM_SUBSCRIPTION_ID env var
  }
}

locals {
  azure_hub_resource_group_name = "${var.azure_hub_resource_name}"
  azure_hub_vnet_name = "${var.azure_hub_resource_name}-vnet"
  azure_primary_resource_group_name = "${var.azure_hub_resource_name}-${var.primary_region}"
  azure_dr_resource_group_name = "${var.azure_hub_resource_name}-${var.dr_region}"
  azure_primary_vnet = "${var.azure_hub_resource_name}-primary-vnet"
  azure_dr_vnet = "${var.azure_hub_resource_name}-dr-vnet"

  azure_subnet_name_by_zone = {
    "1" = "default",
    "2" = "default",
    "3" = "default",
  }  
}
resource "confluent_environment" "main" {
  display_name = "Private-Public-Private"
  stream_governance {
         package = "ESSENTIALS"   # Use "ESSENTIALS" or "ADVANCED"
     }
}

module "jump_cluster" {
  source = "./modules/azure-public"

  cflt_environment = confluent_environment.main
  kafka_cluster_name = var.public_jump_cluster_name
  kafka_cluster_type = "DEDICATED"
  dedicated_cku = 1
  cc_provider = "AZURE"
  cc_provider_region = var.dr_region
}

module "primary_cluster" {
  source = "./modules/azure-private"  
  azure_subscription_id = var.azure_subscription_id
  resource_group = local.azure_primary_resource_group_name
  vnet_name = local.azure_primary_vnet
  vnet_cidr = var.azure_primary_vnet_cidr
  default_subnet_cidr = var.azure_primary_default_subnet_cidr
  subnet_name_by_zone = local.azure_subnet_name_by_zone
  cc_provider = "AZURE"
  cc_provider_region = var.primary_region
  cflt_environment = confluent_environment.main
  kafka_cluster_name = var.private_primary_cluster_name
  kafka_cluster_type = "DEDICATED"
  dedicated_cku = 1
}

module "dr_cluster" {
  source = "./modules/azure-private"  
  azure_subscription_id = var.azure_subscription_id
  resource_group = local.azure_dr_resource_group_name
  vnet_name = local.azure_dr_vnet
  vnet_cidr = var.azure_dr_vnet_cidr
  default_subnet_cidr = var.azure_dr_default_subnet_cidr
  subnet_name_by_zone = local.azure_subnet_name_by_zone
  cc_provider = "AZURE"
  cc_provider_region = var.dr_region
  cflt_environment = confluent_environment.main
  kafka_cluster_name = var.private_dr_cluster_name
  kafka_cluster_type = "DEDICATED"
  dedicated_cku = 1
}

module "peering" {
  source = "./modules/azure-peering"

  hub_resource_group_name = local.azure_hub_resource_group_name
  primary_resource_group_name = module.primary_cluster.resource_group.name
  dr_resource_group_name = module.dr_cluster.resource_group.name
  hub_vnet_name = local.azure_hub_vnet_name
  primary_vnet_name = local.azure_primary_vnet
  dr_vnet_name = local.azure_dr_vnet
  primary_private_dns_domain = module.primary_cluster.dns-domain
  dr_private_dns_domain = module.dr_cluster.dns-domain

  depends_on = [ module.primary_cluster, module.dr_cluster ]

}

module "cc_proxy" {
  source = "./modules/azure-proxy"
  resource_group_name = local.azure_hub_resource_group_name
  vnet_name = local.azure_hub_vnet_name
  allowed_cidrs = var.proxy_allowed_cidrs
}

###### NOTE: RUN THIS TWO MODULES AFTER THE PROXY HAS BEEN CREATED AND ADDED THE DNS OF THE PRIVATE CLUSTERS ADDED TO THE /etc/hosts
### EVEN WHEN THE API KEY IS CREATED VIA THE CONTROL PLANE, THE "TEST" PERFORMED WILL FAIL IF THERES NO CONNECTIVITY TO THE DATA PLANE
### EXAMPLE FOR BROKERS... GIVE THE DNS: lkc-9qrmxm.domdpomv0qw.germanywestcentral.azure.confluent.cloud
### HOSTS FILE: (For a SINGLE_ZONE Cluster) - az might vary
### <proxy-ip> lkc-9qrmxm.domdpomv0qw.germanywestcentral.azure.confluent.cloud
### <proxy-ip> lkc-9qrmxm-g000.az1.domdpomv0qw.germanywestcentral.azure.confluent.cloud
### <proxy-ip> lkc-9qrmxm-g001.az1.domdpomv0qw.germanywestcentral.azure.confluent.cloud
### <proxy-ip> lkc-9qrmxm-g002.az1.domdpomv0qw.germanywestcentral.azure.confluent.cloud

module "primary_apikey" {
  source = "./modules/private-api-key"
  cflt_environment = confluent_environment.main
  kafka_cluster = module.primary_cluster.kafka_cluster
  create_api_keys = var.create_private_cluster_api_keys
}

module "dr_apikey" {
  source = "./modules/private-api-key"
  cflt_environment = confluent_environment.main
  kafka_cluster = module.dr_cluster.kafka_cluster
  create_api_keys = var.create_private_cluster_api_keys
}
