variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "activate_apis" {
  description = "List of APIs to enable."
  type        = list(string)
}

variable "manage_apis" {
  description = <<-EOT
    Whether Terraform should manage (enable/disable) project APIs at all.
    Set to false when the deploying service account does not hold
    serviceusage.services.enable/disable (e.g. AUTH_PERMISSION_DENIED /
    "Permission denied to list Project Services") and the required APIs are
    instead enabled out-of-band by a project admin. Defaults to true.
  EOT
  type        = bool
  default     = true
}
