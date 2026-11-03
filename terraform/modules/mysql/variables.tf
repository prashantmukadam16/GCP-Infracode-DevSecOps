variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "network_id" {
  description = "VPC network self link or ID"
  type        = string
}

variable "mysql_tier" {
  description = "Cloud SQL machine tier"
  type        = string
}

variable "deletion_protection" {
  description = "Prevent accidental Cloud SQL deletion"
  type        = bool
  default     = false
}
