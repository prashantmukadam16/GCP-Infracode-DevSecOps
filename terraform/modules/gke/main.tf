resource "google_compute_subnetwork" "gke" {
  project                  = var.project_id
  name                     = "gke-${var.environment}"
  region                   = var.region
  network                  = var.network_id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods-${var.environment}"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "gke-services-${var.environment}"
    ip_cidr_range = var.services_cidr
  }
}

resource "google_container_cluster" "gke" {
  project          = var.project_id
  name             = "gke-${var.environment}"
  location         = var.region
  enable_autopilot = true
  network          = var.network_id
  subnetwork       = google_compute_subnetwork.gke.id
  networking_mode  = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods-${var.environment}"
    services_secondary_range_name = "gke-services-${var.environment}"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  deletion_protection = var.deletion_protection

  depends_on = [google_compute_subnetwork.gke]
}
