variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "name" {
  description = "Base name used for load balancer resources."
  type        = string
}

variable "instance_group_self_link" {
  description = "Self link of the managed instance group backing the load balancer."
  type        = string
}

variable "backend_port" {
  description = "Port used by the backend service and health check."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Request path used by the backend health check."
  type        = string
  default     = "/"
}

variable "forwarding_rule_port" {
  description = "Port range exposed by the global forwarding rule."
  type        = string
  default     = "80"
}
