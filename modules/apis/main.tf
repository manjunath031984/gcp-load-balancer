# =============================================================================
# Module: apis
# Enables required Google Cloud APIs for the project.
#
# NOTE: If the deploying service account lacks serviceusage.services.enable
# (AUTH_PERMISSION_DENIED / "Permission denied to list Project Services"),
# set var.manage_apis = false so Terraform skips API management entirely
# instead of failing plan/apply. In that case, an admin must ensure the APIs
# listed in var.activate_apis are already enabled on the project.
# =============================================================================

resource "google_project_service" "this" {
  for_each = var.manage_apis ? toset(var.activate_apis) : toset([])

  project                    = var.project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}
