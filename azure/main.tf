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
  public_jump_cluster_name = "public-jump-cluster"
  private_primary_cluster_name = "private-primary-cluster"
  private_dr_cluster_name = "private-dr-cluster"
  azure_hub_resource_group_name = "${var.azure_resource_group_prefix}"
  azure_hub_vnet_name = "${var.azure_resource_group_prefix}-vnet"
  azure_primary_resource_group_name = "${var.azure_resource_group_prefix}-${var.primary_region}"
  azure_dr_resource_group_name = "${var.azure_resource_group_prefix}-${var.dr_region}"
  azure_primary_vnet = "${var.azure_resource_group_prefix}-primary-vnet"
  azure_primary_vnet_cidr = "20.1.0.0/16"
  azure_primary_default_subnet_cidr = "20.1.1.0/24"
  azure_dr_vnet = "${var.azure_resource_group_prefix}-dr-vnet"
  azure_dr_vnet_cidr = "30.1.0.0/16"
  azure_dr_default_subnet_cidr = "30.1.1.0/24"
  azure_subnet_name_by_zone = {
    "1" = "default",
    "2" = "default",
    "3" = "default",
  }
  proxy_allowed_cidrs = ["170.253.50.253/32"]
}
resource "confluent_environment" "main" {
  display_name = "Private-Public-Private"
  stream_governance {
         package = "ESSENTIALS"   # Use "ESSENTIALS" or "ADVANCED"
     }
}

resource "confluent_kafka_cluster" "temp" {
     display_name = "temporary-kafka-cluster"
     availability = "SINGLE_ZONE"
     cloud        = "AZURE"
     region       = "${var.primary_region}"
     basic {}

     environment {
         id = confluent_environment.main.id
     }
 }


module "jump_cluster" {
  source = "./modules/azure-public"

  cflt_environment = confluent_environment.main
  kafka_cluster_name = local.public_jump_cluster_name
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
  vnet_cidr = local.azure_primary_vnet_cidr
  default_subnet_cidr = local.azure_primary_default_subnet_cidr
  subnet_name_by_zone = local.azure_subnet_name_by_zone
  cc_provider = "AZURE"
  cc_provider_region = var.primary_region
  cflt_environment = confluent_environment.main
  kafka_cluster_name = local.private_primary_cluster_name
  kafka_cluster_type = "DEDICATED"
  dedicated_cku = 1
}

module "dr_cluster" {
  source = "./modules/azure-private"  
  azure_subscription_id = var.azure_subscription_id
  resource_group = local.azure_dr_resource_group_name
  vnet_name = local.azure_dr_vnet
  vnet_cidr = local.azure_dr_vnet_cidr
  default_subnet_cidr = local.azure_dr_default_subnet_cidr
  subnet_name_by_zone = local.azure_subnet_name_by_zone
  cc_provider = "AZURE"
  cc_provider_region = var.dr_region
  cflt_environment = confluent_environment.main
  kafka_cluster_name = local.private_dr_cluster_name
  kafka_cluster_type = "DEDICATED"
  dedicated_cku = 1
}

module "peering" {
  source = "./modules/azure-peering"

  hub_resource_group_name = local.azure_hub_resource_group_name
  primary_resource_group_name = local.azure_primary_resource_group_name
  dr_resource_group_name = local.azure_dr_resource_group_name
  hub_vnet_name = local.azure_hub_vnet_name
  primary_vnet_name = local.azure_primary_vnet
  dr_vnet_name = local.azure_dr_vnet
  primary_private_dns_domain = module.primary_cluster.dns-domain
  dr_private_dns_domain = module.dr_cluster.dns-domain
}

module "cc_proxy" {
  source = "./modules/azure-proxy"
  resource_group_name = local.azure_hub_resource_group_name
  vnet_name = local.azure_hub_vnet_name
  allowed_cidrs = local.proxy_allowed_cidrs
}

###### NOTE: RUN THIS TWO MODULES AFTER THE PROXY HAS BEEN CREATED AND ADDED THE DNS OF THE PRIVATE CLUSTERS ADDED TO THE /etc/hosts
### EVEN WHEN THE API KEY IS CREATED VIA THE CONTROL PLANE, THE "TEST" PERFORMED WILL FAIL IF THERES NO CONNECTIVITY TO THE DATA PLANE
### EXAMPLE FOR BROKERS... GIVE THE DNS: lkc-9qrmxm.domdpomv0qw.germanywestcentral.azure.confluent.cloud
### HOSTS FILE: (For a SINGLE_ZONE Cluster)
### <proxy-ip> lkc-9qrmxm.domdpomv0qw.germanywestcentral.azure.confluent.cloud
### <proxy-ip> lkc-9qrmxm-g000.az1.domdpomv0qw.germanywestcentral.azure.confluent.cloud
### <proxy-ip> lkc-9qrmxm-g001.az1.domdpomv0qw.germanywestcentral.azure.confluent.cloud
### <proxy-ip> lkc-9qrmxm-g002.az1.domdpomv0qw.germanywestcentral.azure.confluent.cloud

module "primary_apikey" {
  source = "./modules/private-api-key"
  cflt_environment = confluent_environment.main
  kafka_cluster = module.primary_cluster.kafka_cluster
}

module "dr_apikey" {
  source = "./modules/private-api-key"
  cflt_environment = confluent_environment.main
  kafka_cluster = module.dr_cluster.kafka_cluster
}