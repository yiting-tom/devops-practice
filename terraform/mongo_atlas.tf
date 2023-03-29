provider "mongodbatlas" {
  public_key  = var.mongodbatlas_public_key
  private_key = var.mongodbatlas_private_key
}

# Cluster
resource "mongodbatlas_cluster" "mongo_cluster" {
  project_id = var.mongodbatlas_project_id
  name       = "${var.namespace}-${terraform.workspace}"
  num_shards = 1

  replication_factor           = 3
  cloud_backup                 = true
  auto_scaling_disk_gb_enabled = true
  mongo_db_major_version       = "4.2"

  # Provider Settings "block"
  # https://www.mongodb.com/docs/atlas/reference/google-gcp/#std-label-google-gcp-availability-zones
  provider_name               = "GCP"
  disk_size_gb                = 10
  provider_instance_size_name = "M10"
  provider_region_name        = "ASIA_EAST_2"
}

# DB User
resource "mongodbatlas_database_user" "mongo_user" {
  username           = "${var.namespace}-user-${terraform.workspace}"
  password           = var.mongodbatlas_user_password
  project_id         = var.mongodbatlas_project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = var.namespace
  }
}

# IP Whitelist
resource "mongodbatlas_project_ip_access_list" "gcp_whitelist" {
  project_id = var.mongodbatlas_project_id
  ip_address = google_compute_address.ip_address.address
}
