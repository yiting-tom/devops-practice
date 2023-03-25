# Terraform State Management

## State Management

Terraform manages the state of the infra. it manages in the "state file". The "state file" is a JSON file that stores the current state of the infra. resources, as well as metadata about the resources.

When Terrafrom modifies resources, it updates the "state file" to reflect the current state of the resources. Also, Terrafrom uses this file to track the dependencies between resources.

The "state file" can be stored locally or remotely. When using remote state storage, Terraform stores the state file in a remote backend.

Like the most dependency management tools, Terraform supports locking the state file to prevent multiple users from modifying the same resources simultaneously.

### brief introduction to the state file `terraform.tfstate`

The state file includes information such as resource IDs, network addresses, and other details that Terraform uses to manage the infrastructure resources. When you run terraform apply to update your infrastructure, Terraform will use the state file to determine what changes need to be made and how to make them.

Now, we want to enable cloudbuild and create a trigger for a continuous delivery process. We have 5 files: `variables.tf`, `terraform.tfvars`, `versions.tf`, `main.tf`, and `cloudbuild.tf`

- `variables.tf`: This file defines three global variables that will be used throughout your configuration. The `project_id` variable specifies the GCP project ID to deploy to, `region` specifies the region to deploy to (with a default value of asia-east1), and `namespace` specifies the namespace to use for unique resource naming.

```terraform=
variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  default     = "asia-east1"
  type        = string
}

variable "namespace" {
  description = "The namespace to deploy to use for unique resource naming"
  type        = string
}
```

- `terraform.tfvars`: This file sets the values for the variables defined in `variables.tf`. In this case, it sets the project_id variable to your-project-id, the namespace variable to pipeline, and the region variable to asia-east1.

```terraform=
project_id = "your-project-id"
namespace  = "pipeline"
region     = "asia-east1"
```

- `versions.tf`: This file specifies the required version of Terraform and the required provider version for the Google Cloud provider. In this case, it requires Terraform version 0.13 or higher and the Google Cloud provider version 4.57.0.

```terraform=
terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.57.0"
    }
  }
}
```

- main.tf: This file defines a locals block that defines the services variable as an array that contains the "cloudbuild.googleapis.com" service. It also defines a data block that gets information about the GCP project using the google_project data source. Finally, it defines a resource block that creates a Google Cloud project service for the cloudbuild service.

```terraform=
locals {
  services = [
    "cloudbuild.googleapis.com",
  ]
}

data "google_project" "project" {
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
```

- cloudbuild.tf: This file defines a resource block that creates a Google Cloud Build trigger. It depends on the cloudbuild service created in main.tf. The trigger is set to trigger on any branch name that ends with master and uses the Google Cloud Build service to build and test the code in the specified repository. Finally, it defines a resource block that grants the cloudbuild service account the roles/run.admin and roles/iam.serviceAccountUser roles.

```terraform=
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
```

After complete the script, we run `terraform init` to download and install any required plugins, initialize the backend, and set up the working directory. We'll get

![cmd:tf-init](https://i.imgur.com/hrWs3pA.png)
