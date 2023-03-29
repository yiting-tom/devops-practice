# This file is used to configure the Terraform backend and provider.
terraform {
  backend "gcs" {
    bucket = "devops-demo-4569-terraform"
    prefix = "/state/devops-practice"
  }
}
