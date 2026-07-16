#!/usr/bin/env bash
# =============================================================================
# Installs/verifies the toolchain directly on the Jenkins agent - no Docker
# required. This is used because the Jenkins agent container in this
# environment has no `docker` CLI / socket access, so per-build containers
# are not an option here.
#
# - Terraform and the Google Cloud SDK are fetched as self-contained
#   archives into the Jenkins workspace (no root required).
# - CA certificates / OpenSSL are refreshed via apt-get *only* if the agent
#   is running as root or has passwordless sudo. If neither is available,
#   this step is skipped with a clear warning, since an unprivileged
#   pipeline cannot patch the container's system OpenSSL/trust store -
#   that requires rebuilding the Jenkins agent image itself (see Dockerfile).
# =============================================================================
set -euo pipefail

TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.13.0}"
BIN_DIR="${WORKSPACE}/.bin"
GCLOUD_DIR="${WORKSPACE}/.gcloud-sdk"

mkdir -p "${BIN_DIR}"

echo "===== Refreshing CA certificates / OpenSSL (best effort, requires root) ====="
if [ "$(id -u)" = "0" ]; then
    apt-get update -qq
    apt-get install -y --no-install-recommends ca-certificates openssl curl wget git
    update-ca-certificates
elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends ca-certificates openssl curl wget git
    sudo update-ca-certificates
else
    echo "WARNING: no root/sudo access on this Jenkins agent - skipping OS package refresh."
    echo "         The system OpenSSL/CA trust store cannot be upgraded from an unprivileged"
    echo "         pipeline step. To fully harden the agent, rebuild/replace the Jenkins agent"
    echo "         image using the repo Dockerfile (updated Debian base + OpenSSL 3.x + CA certs)."
fi

echo "===== Installing Terraform ${TERRAFORM_VERSION} (self-contained, no root required) ====="
if [ -x "${BIN_DIR}/terraform" ] && "${BIN_DIR}/terraform" version | grep -q "${TERRAFORM_VERSION}"; then
    echo "Terraform ${TERRAFORM_VERSION} already installed at ${BIN_DIR}/terraform."
else
    curl -fsSL -o /tmp/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip -o -q /tmp/terraform.zip -d "${BIN_DIR}"
    chmod +x "${BIN_DIR}/terraform"
    rm -f /tmp/terraform.zip
fi
"${BIN_DIR}/terraform" version

echo "===== Installing Google Cloud SDK (self-contained, no root required) ====="
if [ -x "${GCLOUD_DIR}/google-cloud-sdk/bin/gcloud" ]; then
    echo "Google Cloud SDK already installed at ${GCLOUD_DIR}/google-cloud-sdk."
else
    curl -fsSL -o /tmp/gcloud.tar.gz \
        "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz"
    mkdir -p "${GCLOUD_DIR}"
    tar -xzf /tmp/gcloud.tar.gz -C "${GCLOUD_DIR}"
    "${GCLOUD_DIR}/google-cloud-sdk/install.sh" --usage-reporting=false --path-update=false --quiet
    rm -f /tmp/gcloud.tar.gz
fi
"${GCLOUD_DIR}/google-cloud-sdk/bin/gcloud" version
