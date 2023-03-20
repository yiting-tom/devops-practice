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