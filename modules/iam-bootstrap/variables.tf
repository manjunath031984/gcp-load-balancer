variable "project_id" {
  description = "GCP project ID to grant IAM roles/custom role on."
  type        = string
}

variable "deployer_service_account_email" {
  description = "Email of the service account Jenkins/Terraform uses to deploy this stack (e.g. infra-admin@<project>.iam.gserviceaccount.com)."
  type        = string
}

variable "use_custom_role" {
  description = "If true, create and grant a single least-privilege custom role instead of the predefined Google-managed roles."
  type        = bool
  default     = false
}
