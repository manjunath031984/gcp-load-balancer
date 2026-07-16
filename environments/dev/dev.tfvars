# =============================================================================
# Environment-specific variables: dev
# Usage: terraform plan -var-file="environments/dev/dev.tfvars"
# =============================================================================

project_id            = "gcp-dev-july-2026"
region                = "us-central1"
zone                  = "us-central1-a"
environment           = "dev"
service_account_email = "infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com"

network_name     = "app-vpc"
subnet_name      = "app-subnet"
subnet_cidr      = "10.10.0.0/24"
enable_flow_logs = true

ssh_source_ranges = ["0.0.0.0/0"]

machine_type  = "e2-micro"
image_project = "ubuntu-os-cloud"
image_family  = "ubuntu-minimal-2604-lts-amd64"
disk_size_gb  = 10
disk_type     = "pd-balanced"
instance_tags = ["http-server", "https-server", "ssh-allowed"]

mig_name                       = "app-mig"
target_size                    = 2
base_instance_name             = "app-instance"
health_check_initial_delay_sec = 300

lb_name = "app-lb"
lb_port = 80
