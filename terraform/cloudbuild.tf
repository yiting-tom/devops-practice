# resource "google_cloudbuildv2_repository" "my-repository" {
#   provider = google-beta
#   project = var.project_id
#   location = var.region
#   name = namespace
#   parent_connection = google_cloudbuildv2_connection.my-connection.name
#   remote_uri = var.remote_uri
# }

resource "google_cloudbuild_trigger" "trigger" {
  depends_on = [
    google_project_service.service["cloudbuild.googleapis.com"],
  ]

  trigger_template {
    branch_name = "*master$"
    repo_name   = google_sourcerepo_repository.repo.name
  }

  build {
    step {
      name = "gcr.io/cloud-builders/go"
      args = ["test"]
      env  = ["PROJECT_ROOT=${var.namespace}"]
    }
  }
}

resource "google_project_iam_member" "cloudbuild_roles" {
  depends_on = [google_cloudbuild_trigger.trigger]
  for_each = toset([
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}