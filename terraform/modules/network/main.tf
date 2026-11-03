resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "vpc-${var.environment}"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "web" {
  project                  = var.project_id
  name                     = "web-${var.environment}"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range             = "10.10.1.0/24"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "app" {
  project                  = var.project_id
  name                     = "app-${var.environment}"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range             = "10.10.2.0/24"
  private_ip_google_access = true
}

resource "google_compute_global_address" "private_range" {
  project       = var.project_id
  name          = "sql-private-range-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.private_range.name
  ]
}

# Example app firewall. This allows TCP/80 from the app subnet only.
# Add a load balancer proxy-only subnet and health-check ranges when
# you implement a load balancer. Avoid broad internet ingress.
resource "google_compute_firewall" "allow_app_http" {
  project   = var.project_id
  name      = "allow-app-http-${var.environment}"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["10.10.2.0/24"]
  target_tags   = ["app-server"]
}
