# =============================================================================
# Root Module Variables
# =============================================================================

variable "project_id" {
  description = "GCP project ID where all resources will be created."
  type        = string
}

variable "region" {
  description = "GCP region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for zonal resources."
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "service_account_email" {
  description = "Service account email attached to compute instances."
  type        = string
}

variable "activate_apis" {
  description = "List of GCP APIs to enable on the project."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "manage_apis" {
  description = <<-EOT
    Whether Terraform should enable/disable the APIs in var.activate_apis.
    Set to false if the deploying service account lacks
    serviceusage.services.enable (AUTH_PERMISSION_DENIED) and instead have a
    project admin enable the required APIs out-of-band. Defaults to true.
  EOT
  type        = bool
  default     = true
}

# --- Network -----------------------------------------------------------------

variable "network_name" {
  description = "Name of the custom VPC network."
  type        = string
  default     = "app-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet."
  type        = string
  default     = "app-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet."
  type        = string
  default     = "10.10.0.0/24"
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs on the subnet."
  type        = bool
  default     = true
}

# --- Firewall ------------------------------------------------------------

variable "ssh_source_ranges" {
  description = "Source IP ranges allowed to reach instances via SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --- Compute / Instance Template ------------------------------------------

variable "machine_type" {
  description = "Machine type for compute instances."
  type        = string
  default     = "e2-micro"
}

variable "image_project" {
  description = "Project that hosts the boot image."
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "image_family" {
  description = "Image family to use for the boot disk."
  type        = string
  default     = "ubuntu-minimal-2604-lts-amd64"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 10
}

variable "disk_type" {
  description = "Boot disk type."
  type        = string
  default     = "pd-balanced"
}

variable "instance_tags" {
  description = "Network tags applied to instances (used by firewall rules)."
  type        = list(string)
  default     = ["http-server", "https-server", "ssh-allowed"]
}

variable "startup_script_path" {
  description = "Path to the Apache startup script (relative to root module)."
  type        = string
  default     = "startup-script/apache.sh"
}

# --- Managed Instance Group ------------------------------------------------

variable "mig_name" {
  description = "Name of the regional managed instance group."
  type        = string
  default     = "app-mig"
}

variable "target_size" {
  description = "Fixed number of instances in the MIG (no autoscaling)."
  type        = number
  default     = 2
}

variable "mig_distribution_policy_zones" {
  description = "Fixed set of zones the regional MIG is pinned to. Must have at least one zone; update_policy.max_surge_fixed is derived from this list's length so it satisfies GCP's regional MIG constraint (fixed maxSurge/maxUnavailable must be 0 or >= zone count) without requiring target_size >= 10."
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b"]
}

variable "base_instance_name" {
  description = "Base name used for instances created by the MIG."
  type        = string
  default     = "app-instance"
}

variable "health_check_initial_delay_sec" {
  description = "Initial delay in seconds before auto-healing health checks start."
  type        = number
  default     = 300
}

# --- Load Balancer -----------------------------------------------------------

variable "lb_name" {
  description = "Base name used for load balancer resources."
  type        = string
  default     = "app-lb"
}

variable "lb_port" {
  description = "Port the load balancer listens on and forwards to backends."
  type        = number
  default     = 80
}
