provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

locals {
  services = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
  ]
}

resource "google_project_service" "service" {
  for_each = toset(local.services)
  project  = var.project_id
  service  = each.key

  disable_on_destroy         = true
  disable_dependent_services = true

  provisioner "local-exec" {
    command = "sleep 10"
  }
}
