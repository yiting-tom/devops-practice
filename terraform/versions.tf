terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.58.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.8.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.2.0"
    }
  }
}
