# =============================================================================
# Jenkins Terraform/GCP Build Agent Image
#
# ROOT CAUSE THIS IMAGE FIXES
# ---------------------------
# "remote error: tls: protocol version not supported" is a TLS *alert sent
# back by Google's frontend (storage.googleapis.com)* because the client's
# ClientHello only offered TLS versions Google no longer accepts (SSLv3/
# TLS 1.0/TLS 1.1). This happens when the container's OpenSSL/CA trust
# store and Go-compiled tooling (terraform, gcloud, provider binaries) are
# old enough that TLS 1.2/1.3 is either disabled or negotiated incorrectly
# (old libssl, stale /etc/ssl/openssl.cnf forcing legacy providers, or
# missing updated CA bundle). This image uses a current Debian base with
# OpenSSL 3.x (TLS 1.3 capable), refreshed CA certificates, and the latest
# stable Terraform + Google Cloud SDK builds so all TLS handshakes made
# from this agent negotiate TLS 1.2/1.3 correctly.
# =============================================================================
FROM debian:bookworm-slim

ARG TERRAFORM_VERSION=1.13.0

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# ---------------------------------------------------------------------------
# 1. Refresh OS packages, CA trust store, OpenSSL, and core CLI tooling
# ---------------------------------------------------------------------------
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        openssl \
        libssl3 \
        curl \
        wget \
        git \
        gnupg \
        lsb-release \
        apt-transport-https \
        unzip \
        dnsutils \
        iputils-ping \
        jq \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 2. Google Cloud SDK - installed from Google's official apt repo so it is
#    always the current release (statically linked TLS 1.3 support)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
        > /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-cli && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 3. Terraform - installed from HashiCorp's official apt repo (signed,
#    latest stable release, TLS-1.3-capable Go build)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends "terraform=${TERRAFORM_VERSION}-*" && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 4. Sanity-check the toolchain at build time so a broken image never ships
# ---------------------------------------------------------------------------
RUN openssl version \
    && terraform version \
    && gcloud --version \
    && curl --version | head -n1 \
    && git --version

WORKDIR /workspace
