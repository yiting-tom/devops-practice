# IP address
resource "google_compute_address" "ip_address" {
  depends_on = [
    google_project_service.service
  ]
  name = "${var.namespace}-ip-${terraform.workspace}"
}

# Network
data "google_compute_network" "default" {
  depends_on = [
    google_compute_address.ip_address
  ]
  name = "default"
}

# Firewall
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-${terraform.workspace}"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [
    "allow-http-${terraform.workspace}"
  ]
}
