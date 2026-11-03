variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name used in resource names"
  type        = string
  default     = "dev"
}

variable "mysql_tier" {
  description = "Cloud SQL machine tier; review cost before deployment"
  type        = string
  default     = "db-custom-2-7680"
}

variable "mysql_deletion_protection" {
  description = "Protect Cloud SQL from accidental deletion"
  type        = bool
  default     = false
}

variable "compute_zones" {
  description = "Zones used by the regional Compute Engine MIG"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b"]
}

variable "gke_subnet_cidr" {
  description = "Primary subnet range dedicated to GKE nodes"
  type        = string
  default     = "10.11.0.0/20"
}

variable "gke_pods_cidr" {
  description = "Secondary subnet range for GKE Pods"
  type        = string
  default     = "10.32.0.0/16"
}

variable "gke_services_cidr" {
  description = "Secondary subnet range for GKE Services"
  type        = string
  default     = "10.48.0.0/20"
}

variable "gke_deletion_protection" {
  description = "Protect GKE cluster from accidental deletion"
  type        = bool
  default     = false
}

variable "master_authorized_cidr" {
  description = "Jenkins public egress IP in CIDR notation"
  type        = string
}
