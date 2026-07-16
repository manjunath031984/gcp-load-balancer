variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "activate_apis" {
  description = "List of APIs to enable."
  type        = list(string)
}
