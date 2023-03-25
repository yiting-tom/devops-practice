locals {
  services = [
    "iap.googleapis.com",
  ]
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials)
}

resource "google_project" "project" {
  name       = var.namespace
  project_id = var.project_id
}

resource "google_project_service" "service" {
  for_each = toset(local.services)

  project                    = google_project.project.project_id
  service                    = each.key
  disable_dependent_services = true
  disable_on_destroy         = true

  provisioner "local-exec" {
    command = "sleep 10"
  }

  timeouts {
    create = "5m"
    update = "10m"
  }

}

resource "google_iap_brand" "brand" {
  support_email     = var.support_email
  project           = google_project.project.project_id
  application_title = var.namespace
}

resource "google_iap_client" "client" {
  display_name = var.namespace
  brand        = google_iap_brand.brand.name
}
