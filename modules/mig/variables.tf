variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Region for the regional managed instance group."
  type        = string
}

variable "name" {
  description = "Name of the managed instance group."
  type        = string
}

variable "base_instance_name" {
  description = "Base name used for instances created by the MIG."
  type        = string
}

variable "instance_template_self_link" {
  description = "Self link of the instance template to use."
  type        = string
}

variable "target_size" {
  description = "Fixed number of instances in the MIG."
  type        = number
  default     = 2
}

variable "distribution_policy_zones" {
  description = "Fixed set of zones the regional MIG is pinned to. Required so that update_policy.max_surge_fixed (set equal to the zone count) satisfies the GCP API constraint that fixed maxSurge/maxUnavailable be 0 or >= the number of zones the MIG spans."
  type        = list(string)
}

variable "named_port" {
  description = "Port exposed via the named port 'http'."
  type        = number
  default     = 80
}

variable "health_check_port" {
  description = "Port used by the auto-healing health check."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Request path used by the auto-healing health check."
  type        = string
  default     = "/"
}

variable "health_check_initial_delay_sec" {
  description = "Initial delay in seconds before auto-healing health checks start."
  type        = number
  default     = 300
}
