#!/usr/bin/env bash
# =============================================================================
# Activates the GCP service account credential inside the toolchain container.
# =============================================================================
set -euo pipefail

gcloud auth activate-service-account --key-file="${GOOGLE_APPLICATION_CREDENTIALS}"
gcloud config set project "${GOOGLE_CLOUD_PROJECT}"
