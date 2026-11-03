output "network_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "app_subnet_id" {
  description = "Application subnet ID"
  value       = google_compute_subnetwork.app.id
}

output "web_subnet_id" {
  description = "Web subnet ID"
  value       = google_compute_subnetwork.web.id
}

output "private_service_connection_id" {
  description = "Private Service Access connection ID"
  value       = google_service_networking_connection.private_vpc_connection.id
}
