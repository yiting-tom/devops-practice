provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Zone
data "cloudflare_zones" "filtered" {
  filter {
    name = var.cloudflare_domain
  }
}

# DNS Record
resource "cloudflare_record" "dns_record" {
  zone_id = data.cloudflare_zones.filtered.zones[0].id
  name    = "${var.namespace}${terraform.workspace == "prod" ? "" : "-${terraform.workspace}"}"
  type    = "A"
  value   = google_compute_address.ip_address.address
  proxied = true
}
