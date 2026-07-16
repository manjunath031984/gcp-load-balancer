# =============================================================================
# Remote State Backend - Google Cloud Storage
# NOTE: Backend configuration blocks do not support variables. The bucket
# must already exist before running `terraform init`.
#   gsutil mb -p gcp-dev-july-2026 -l us-central1 \
#     gs://gcp-dev-july-2026-terraform-state
#   gsutil versioning set on gs://gcp-dev-july-2026-terraform-state
#
# NOTE: The GCS backend talks to storage.googleapis.com exclusively over
# TLS 1.2/1.3 (enforced server-side by Google's frontends). If the Terraform
# binary/CLI runs on a host with an outdated OpenSSL/Go TLS stack, init will
# fail with "remote error: tls: protocol version not supported". This is
# fixed at the execution-environment level (see Dockerfile), not here.
# =============================================================================

terraform {
  backend "gcs" {
    bucket = "gcp-dev-july-2026-terraform-state"
    prefix = "alb/dev"
  }
}
