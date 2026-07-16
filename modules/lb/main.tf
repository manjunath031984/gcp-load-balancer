# =============================================================================
# Module: lb
# Global External HTTP Application Load Balancer:
#   Health Check -> Backend Service -> URL Map -> Target HTTP Proxy ->
#   Global Static IP -> Global Forwarding Rule
# =============================================================================

resource "google_compute_health_check" "lb" {
  project             = var.project_id
  name                = "${var.name}-hc"
  description         = "Health check used by the load balancer backend service."
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.backend_port
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "this" {
  project               = var.project_id
  name                  = "${var.name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 30
  enable_cdn            = false

  health_checks = [google_compute_health_check.lb.id]

  backend {
    group           = var.instance_group_self_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "this" {
  project         = var.project_id
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.this.id
}

resource "google_compute_target_http_proxy" "this" {
  project = var.project_id
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.this.id
}

resource "google_compute_global_address" "this" {
  project      = var.project_id
  name         = "${var.name}-ip"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "this" {
  project               = var.project_id
  name                  = "${var.name}-fwd-rule"
  ip_address            = google_compute_global_address.this.address
  ip_protocol           = "TCP"
  port_range            = var.forwarding_rule_port
  target                = google_compute_target_http_proxy.this.id
  load_balancing_scheme = "EXTERNAL"
}
