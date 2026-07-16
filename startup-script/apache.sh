#!/bin/bash
# =============================================================================
# Apache2 Startup Script for GCP Compute Instances
# Installs Apache2 and renders an index.html with instance metadata.
# =============================================================================
set -euo pipefail

exec > >(tee -a /var/log/startup-script.log) 2>&1

echo "=== Starting Apache2 installation - $(date) ==="

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y apache2 curl

# --- Fetch instance metadata ---------------------------------------------
METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
METADATA_HEADER="Metadata-Flavor: Google"

PROJECT_ID="$(curl -s -H "${METADATA_HEADER}" "${METADATA_URL}/project/project-id")"
INSTANCE_NAME="$(curl -s -H "${METADATA_HEADER}" "${METADATA_URL}/instance/name")"
ZONE_FULL="$(curl -s -H "${METADATA_HEADER}" "${METADATA_URL}/instance/zone")"
ZONE="$(echo "${ZONE_FULL}" | awk -F/ '{print $NF}')"
HOSTNAME_FULL="$(hostname -f 2>/dev/null || hostname)"
CURRENT_DATE="$(date '+%Y-%m-%d')"
CURRENT_TIME="$(date '+%H:%M:%S %Z')"

# --- Render index.html -----------------------------------------------------
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>GCP HTTP Load Balancer - Backend Instance</title>
  <style>
    body {
      font-family: 'Segoe UI', Arial, sans-serif;
      background-color: #f4f6f8;
      color: #202124;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }
    .card {
      background: #ffffff;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.15);
      padding: 40px;
      min-width: 480px;
    }
    h1 {
      color: #1a73e8;
      font-size: 24px;
      margin-bottom: 20px;
      text-align: center;
    }
    table {
      width: 100%;
      border-collapse: collapse;
    }
    th, td {
      text-align: left;
      padding: 10px 14px;
      border-bottom: 1px solid #e0e0e0;
    }
    th {
      width: 40%;
      color: #5f6368;
      font-weight: 600;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>GCP Global HTTP Load Balancer</h1>
    <table>
      <tr><th>Project ID</th><td>${PROJECT_ID}</td></tr>
      <tr><th>Hostname</th><td>${HOSTNAME_FULL}</td></tr>
      <tr><th>Instance Name</th><td>${INSTANCE_NAME}</td></tr>
      <tr><th>Zone</th><td>${ZONE}</td></tr>
      <tr><th>Date</th><td>${CURRENT_DATE}</td></tr>
      <tr><th>Time</th><td>${CURRENT_TIME}</td></tr>
    </table>
  </div>
</body>
</html>
EOF

chown www-data:www-data /var/www/html/index.html
chmod 644 /var/www/html/index.html

systemctl enable apache2
systemctl restart apache2

echo "=== Apache2 installation complete - $(date) ==="
