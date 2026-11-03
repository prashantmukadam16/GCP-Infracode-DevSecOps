variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Regional location for the GKE Autopilot cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "network_id" {
  description = "Self-link or ID of the existing VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "Primary CIDR range for the GKE subnet"
  type        = string
}

variable "pods_cidr" {
  description = "Secondary CIDR range for GKE Pods"
  type        = string
}

variable "services_cidr" {
  description = "Secondary CIDR range for GKE Services"
  type        = string
}

variable "deletion_protection" {
  description = "Protect the GKE cluster from accidental deletion"
  type        = bool
  default     = false
}
