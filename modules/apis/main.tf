# =============================================================================
# Module: apis
# Enables required Google Cloud APIs for the project.
# =============================================================================

resource "google_project_service" "this" {
  for_each = toset(var.activate_apis)

  project                    = var.project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}
