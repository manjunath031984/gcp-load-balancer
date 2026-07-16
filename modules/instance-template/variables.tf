variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the instance template."
  type        = string
}

variable "name_prefix" {
  description = "Name prefix for the instance template (Terraform appends a unique suffix)."
  type        = string
}

variable "machine_type" {
  description = "Machine type for instances."
  type        = string
  default     = "e2-micro"
}

variable "image_project" {
  description = "Project that hosts the boot image."
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "image_family" {
  description = "Image family for the boot disk."
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

variable "network_self_link" {
  description = "Self link of the VPC network."
  type        = string
}

variable "subnetwork_self_link" {
  description = "Self link of the subnetwork."
  type        = string
}

variable "service_account_email" {
  description = "Service account email attached to instances."
  type        = string
}

variable "startup_script" {
  description = "Contents of the startup script to run on instance boot."
  type        = string
}

variable "tags" {
  description = "Network tags applied to instances."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels applied to instances."
  type        = map(string)
  default     = {}
}
