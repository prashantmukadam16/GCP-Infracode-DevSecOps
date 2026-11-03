output "cluster_name" {
  description = "GKE Autopilot cluster name"
  value       = google_container_cluster.gke.name
}

output "cluster_location" {
  description = "GKE cluster location"
  value       = google_container_cluster.gke.location
}

output "cluster_endpoint" {
  description = "GKE Kubernetes API endpoint"
  value       = google_container_cluster.gke.endpoint
  sensitive   = true
}

output "subnet_name" {
  description = "Dedicated GKE subnet name"
  value       = google_compute_subnetwork.gke.name
}
