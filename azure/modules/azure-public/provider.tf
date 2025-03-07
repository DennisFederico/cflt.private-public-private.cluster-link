terraform {
  required_providers {    
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.12.0"
    }
  }
  required_version = ">=1.5.0"
}