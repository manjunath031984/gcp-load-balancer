# =============================================================================
# Partial GCS backend configuration for the "dev" environment.
# Usage: terraform init -backend-config="environments/dev/backend.hcl"
# =============================================================================

bucket = "gcp-dev-july-2026-terraform-state"
prefix = "alb/dev"
