resource "google_compute_instance_template" "app" {
  project      = var.project_id
  name_prefix  = "app-${var.environment}-"
  machine_type = "e2-medium"
  tags         = ["app-server"]

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
  }

  network_interface {
    subnetwork = var.subnet_id
    # No external IP. Add controlled egress (e.g. Cloud NAT) or
    # bake dependencies into a custom image for private-only instances.
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "Application server: ${var.environment}" > /var/www/html/index.nginx-debian.html
  SCRIPT

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_health_check" "app" {
  project = var.project_id
  name = "app-health-${var.environment}"

  http_health_check {
    port         = 80
    request_path = "/"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

resource "google_compute_region_instance_group_manager" "app" {
  project            = var.project_id
  name               = "app-mig-${var.environment}"
  region             = var.region
  base_instance_name = "app-${var.environment}"

  version {
    instance_template = google_compute_instance_template.app.id
  }

  distribution_policy_zones = var.zones

  target_size = 2

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.app.id
    initial_delay_sec = 120
  }
}

resource "google_compute_region_autoscaler" "app" {
  project = var.project_id
  name   = "app-autoscaler-${var.environment}"
  region = var.region
  target = google_compute_region_instance_group_manager.app.id

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 5
    cooldown_period = 60

    cpu_utilization {
      target = 0.60
    }
  }
}
