output "vpc_id" {
  description = "VPC network ID"
  value       = module.network.network_id
}

output "web_subnet_id" {
  description = "Web subnet ID"
  value       = module.network.web_subnet_id
}

output "app_subnet_id" {
  description = "Application subnet ID"
  value       = module.network.app_subnet_id
}

output "mysql_private_ip" {
  description = "Cloud SQL private IP address"
  value       = module.mysql.mysql_private_ip
}

output "mysql_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.mysql.mysql_connection_name
}

output "mig_name" {
  description = "Regional Managed Instance Group name"
  value       = module.autoscaling.mig_name
}

output "gke_cluster_name" {
  description = "GKE Autopilot cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_location" {
  description = "GKE cluster region"
  value       = module.gke.cluster_location
}

output "gke_subnet_name" {
  description = "Dedicated GKE subnet name"
  value       = module.gke.subnet_name
}
