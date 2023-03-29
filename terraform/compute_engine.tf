# Compute Engine OS
data "google_compute_image" "cos" {
  depends_on = [google_project_service.service]
  family     = "cos-101-lts"
  project    = "cos-cloud"
}

# Compute Instance
resource "google_compute_instance" "instance" {
  depends_on = [
    google_project_service.service
  ]
  name         = "${var.namespace}-vm-${terraform.workspace}"
  machine_type = var.machine_type
  zone         = var.zone

  tags = google_compute_firewall.allow_http.target_tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    network = data.google_compute_network.default.name

    access_config {
      nat_ip = google_compute_address.ip_address.address
    }
  }

  service_account {
    scopes = ["storage-ro"]
  }
}
