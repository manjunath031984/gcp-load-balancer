# =============================================================================
# Environment: dev
# =============================================================================

project_id            = "gcp-dev-july-2026"
region                = "us-central1"
zone                  = "us-central1-a"
environment           = "dev"
service_account_email = "infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com"

# infra-admin currently lacks serviceusage.services.enable/list (AUTH_PERMISSION_DENIED).
# Skip API management until an admin grants roles/serviceusage.serviceUsageAdmin
# or enables the APIs in variables.tf's activate_apis list out-of-band.
manage_apis = false

# --- Network -----------------------------------------------------------------
network_name     = "app-vpc"
subnet_name      = "app-subnet"
subnet_cidr      = "10.10.0.0/24"
enable_flow_logs = true

# --- Firewall ------------------------------------------------------------
ssh_source_ranges = ["0.0.0.0/0"]

# --- Compute / Instance Template ------------------------------------------
machine_type  = "e2-micro"
image_project = "ubuntu-os-cloud"
image_family  = "ubuntu-minimal-2604-lts-amd64"
disk_size_gb  = 10
disk_type     = "pd-balanced"
instance_tags = ["http-server", "https-server", "ssh-allowed"]

# --- Managed Instance Group ------------------------------------------------
mig_name                       = "app-mig"
target_size                    = 2
base_instance_name             = "app-instance"
health_check_initial_delay_sec = 300

# --- Load Balancer -----------------------------------------------------------
lb_name = "app-lb"
lb_port = 80
