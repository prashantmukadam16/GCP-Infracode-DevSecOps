output "mig_name" {
  description = "Regional Managed Instance Group name"
  value       = google_compute_region_instance_group_manager.app.name
}

output "instance_template_id" {
  description = "Instance template ID"
  value       = google_compute_instance_template.app.id
}
