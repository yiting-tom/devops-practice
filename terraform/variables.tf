variable "project_id" {
  description = "The project ID to deploy"
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

variable "support_email" {
  description = "The support email to use for IAP"
  type        = string
}

variable "credentials" {
  description = "The credentials to use for GCP"
  type        = string
}
