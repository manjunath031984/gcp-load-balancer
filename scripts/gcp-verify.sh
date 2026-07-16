#!/usr/bin/env bash
# =============================================================================
# Prints active gcloud identity/config so the pipeline log proves which
# credentials are being used for the Terraform run.
# =============================================================================
set -euo pipefail

echo "===== Active gcloud accounts ====="
gcloud auth list
echo "===== Active gcloud configuration ====="
gcloud config list
