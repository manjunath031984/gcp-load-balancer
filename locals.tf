# =============================================================================
# Local Values
# =============================================================================

locals {
  name_prefix = "${var.environment}-${var.region}"

  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
    project     = replace(var.project_id, "_", "-")
  }

  network_name = "${var.environment}-${var.network_name}"
  subnet_name  = "${var.environment}-${var.subnet_name}"
  mig_name     = "${var.environment}-${var.mig_name}"
  lb_name      = "${var.environment}-${var.lb_name}"

  startup_script = file("${path.module}/${var.startup_script_path}")
}
