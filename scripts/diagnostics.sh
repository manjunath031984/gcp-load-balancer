#!/usr/bin/env bash
# =============================================================================
# Environment & TLS diagnostics - run inside the toolchain container.
# =============================================================================
set -euo pipefail

echo "===== OS Information ====="
cat /etc/os-release
uname -a

echo "===== Tool Versions ====="
terraform version
openssl version -a
gcloud --version
curl --version | head -n1
git --version

echo "===== Proxy / Firewall Environment Variables ====="
env | grep -i -E "proxy|no_proxy" || echo "No proxy variables set."

echo "===== DNS Resolution ====="
getent hosts registry.terraform.io
getent hosts storage.googleapis.com

echo "===== Basic HTTPS Connectivity ====="
curl -sSf -o /dev/null -w "registry.terraform.io -> HTTP %{http_code}, TLS %{tls_version}\n" https://registry.terraform.io/
curl -sSf -o /dev/null -w "storage.googleapis.com -> HTTP %{http_code}, TLS %{tls_version}\n" https://storage.googleapis.com/

echo "===== TLS 1.2 Handshake Check ====="
echo | openssl s_client -connect registry.terraform.io:443 -tls1_2 -brief 2>&1 | grep -E "Protocol|Cipher|error" || true
echo | openssl s_client -connect storage.googleapis.com:443 -tls1_2 -brief 2>&1 | grep -E "Protocol|Cipher|error" || true

echo "===== TLS 1.3 Handshake Check ====="
echo | openssl s_client -connect registry.terraform.io:443 -tls1_3 -brief 2>&1 | grep -E "Protocol|Cipher|error" || true
echo | openssl s_client -connect storage.googleapis.com:443 -tls1_3 -brief 2>&1 | grep -E "Protocol|Cipher|error" || true
