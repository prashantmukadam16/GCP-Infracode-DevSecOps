output "mysql_private_ip" {
  description = "Cloud SQL private IP"
  value       = google_sql_database_instance.mysql.private_ip_address
}

output "mysql_connection_name" {
  description = "Cloud SQL connection name"
  value       = google_sql_database_instance.mysql.connection_name
}

output "database_name" {
  description = "Application database name"
  value       = google_sql_database.app.name
}
