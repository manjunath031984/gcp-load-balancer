# =============================================================================
# Remote State Backend - Google Cloud Storage
# NOTE: Backend configuration blocks do not support variables. The bucket
# must already exist before running `terraform init`.
#   gsutil mb -p gcp-dev-july-2026 -l us-central1 \
#     gs://gcp-dev-july-2026-terraform-state
#   gsutil versioning set on gs://gcp-dev-july-2026-terraform-state
# =============================================================================

terraform {
  backend "gcs" {
    bucket = "gcp-dev-july-2026-terraform-state"
    prefix = "alb/dev"
  }
}
