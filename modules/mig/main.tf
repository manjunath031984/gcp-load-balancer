# =============================================================================
# Module: mig
# Regional Managed Instance Group (fixed size, no autoscaling) with
# auto-healing based on an HTTP health check.
# =============================================================================

resource "google_compute_health_check" "autohealing" {
  project             = var.project_id
  name                = "${var.name}-autoheal-hc"
  description         = "Health check used for MIG auto-healing."
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_region_instance_group_manager" "this" {
  project = var.project_id
  region  = var.region
  name    = var.name

  base_instance_name = var.base_instance_name
  target_size        = var.target_size

  distribution_policy_zones = var.distribution_policy_zones

  version {
    instance_template = var.instance_template_self_link
  }

  named_port {
    name = "http"
    port = var.named_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing.id
    initial_delay_sec = var.health_check_initial_delay_sec
  }

  # NOTE: percent-based updatePolicy.maxSurge is only allowed for regional
  # MIGs with target_size >= 10, and fixed values must be either 0 or >= the
  # number of zones the MIG spans. distribution_policy_zones pins this MIG to
  # a known, fixed set of zones so max_surge_fixed can be set equal to that
  # zone count, satisfying the API constraint for any target_size.
  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = length(var.distribution_policy_zones)
    max_unavailable_fixed        = 0
    instance_redistribution_type = "PROACTIVE"
  }
}
