terraform {
  required_providers {    
    confluent = {
      source = "confluentinc/confluent"
      version = ">=2.7.0"
    }
  }
  required_version = ">=1.3.0"
}