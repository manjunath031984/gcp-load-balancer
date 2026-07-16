# =============================================================================
# Module: instance-template
# Instance template for Ubuntu 26.04 LTS Minimal, e2-micro, pd-balanced disk.
# =============================================================================

resource "google_compute_instance_template" "this" {
  project     = var.project_id
  name_prefix = "${var.name_prefix}-"
  description = "Instance template for Apache web servers behind the HTTP load balancer."
  region      = var.region

  machine_type = var.machine_type
  tags         = var.tags

  disk {
    source_image = "${var.image_project}/${var.image_family}"
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
  }

  network_interface {
    network    = var.network_self_link
    subnetwork = var.subnetwork_self_link

    access_config {
      # Ephemeral public IP for outbound package installation / SSH access.
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = var.startup_script

  labels = var.labels

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  lifecycle {
    create_before_destroy = true
  }
}
