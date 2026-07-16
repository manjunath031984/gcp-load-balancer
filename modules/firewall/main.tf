# =============================================================================
# Module: firewall
# HTTP, HTTPS, SSH, Internal, and Google Health Check firewall rules.
# =============================================================================

resource "google_compute_firewall" "allow_http" {
  project     = var.project_id
  name        = "${var.name_prefix}-allow-http"
  network     = var.network_self_link
  description = "Allow inbound HTTP traffic on port 80."
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow_https" {
  project     = var.project_id
  name        = "${var.name_prefix}-allow-https"
  network     = var.network_self_link
  description = "Allow inbound HTTPS traffic on port 443."
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

resource "google_compute_firewall" "allow_ssh" {
  project     = var.project_id
  name        = "${var.name_prefix}-allow-ssh"
  network     = var.network_self_link
  description = "Allow inbound SSH traffic on port 22."
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh-allowed"]
}

resource "google_compute_firewall" "allow_internal" {
  project     = var.project_id
  name        = "${var.name_prefix}-allow-internal"
  network     = var.network_self_link
  description = "Allow internal traffic between resources within the subnet."
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
}

resource "google_compute_firewall" "allow_health_checks" {
  project     = var.project_id
  name        = "${var.name_prefix}-allow-health-checks"
  network     = var.network_self_link
  description = "Allow Google Cloud health check probes to reach backend instances."
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  # Google Cloud health check and load balancer source ranges.
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server", "https-server"]
}
