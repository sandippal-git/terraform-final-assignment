terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.5.2"
    }
    aws = {
    source = "hashicorp/aws"
    version = "5.74.0"
    }
    # provider { } 
    # provider2 { }
  }
}
provider "local" {
  # Configuration options
}
provider "aws" {
  region     = "us-east-2"
}
provider "tls" {
  # Configuration options
}