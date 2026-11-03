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

variable "subnet_id" {
  description = "Subnet ID for app instances"
  type        = string
}

variable "zones" {
  description = "Zones for the regional managed instance group"
  type        = list(string)
}
