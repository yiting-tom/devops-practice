locals {
  services = [
    "cloudbuild.googleapis.com",
  ]
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

