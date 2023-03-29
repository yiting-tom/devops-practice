#########################################################
# Project variables
#########################################################
variable "namespace" {
  type        = string
  description = "The namespace of the project"
}

variable "project_id" {
  type        = string
  description = "The project id"
}

variable "credentials_file" {
  type        = string
  description = "The path to the credentials file"
}

variable "region" {
  type        = string
  description = "The region of the project"
  default     = "asia-east1"
}

variable "zone" {
  type        = string
  description = "The zone of the project"
  default     = "asia-east1-c"
}


#########################################################
# GCE variables
#########################################################
variable "machine_type" {
  type        = string
  description = "The machine type of the GCE instance"
  default     = "f1-micro"
}


#########################################################
# MongoDB Atlas variables
#########################################################
variable "mongodbatlas_project_id" {
  type        = string
  description = "The project id of the MongoDB Atlas"
}

variable "mongodbatlas_public_key" {
  type        = string
  description = "The public key of the MongoDB Atlas"
}

variable "mongodbatlas_private_key" {
  type        = string
  description = "The private key of the MongoDB Atlas"
}

variable "mongodbatlas_user_password" {
  type        = string
  description = "The password of the MongoDB Atlas"
}

#########################################################
# Cloudflare variables
#########################################################
variable "cloudflare_api_token" {
  type        = string
  description = "The API token of the Cloudflare account"
}
variable "cloudflare_domain" {
  type        = string
  description = "The domain of the Cloudflare account"
}
