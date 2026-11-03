module "network" {
  source = "./modules/network"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  depends_on = [google_project_service.required_apis]
}

module "mysql" {
  source = "./modules/mysql"

  project_id          = var.project_id
  region              = var.region
  environment         = var.environment
  network_id          = module.network.network_id
  mysql_tier          = var.mysql_tier
  deletion_protection = var.mysql_deletion_protection

  depends_on = [
    module.network,
    google_project_service.required_apis
  ]
}

module "autoscaling" {
  source = "./modules/autoscaling"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  subnet_id   = module.network.app_subnet_id
  zones       = var.compute_zones

  depends_on = [google_project_service.required_apis]
}

module "gke" {
  source = "./modules/gke"

  project_id          = var.project_id
  region              = var.region
  environment         = var.environment
  network_id          = module.network.network_id
  subnet_cidr         = var.gke_subnet_cidr
  pods_cidr           = var.gke_pods_cidr
  services_cidr       = var.gke_services_cidr
  deletion_protection = var.gke_deletion_protection

  depends_on = [google_project_service.required_apis]
  master_authorized_cidr = var.master_authorized_cidr
}
