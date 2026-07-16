variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "name_prefix" {
  description = "Prefix applied to firewall rule names."
  type        = string
}

variable "network_self_link" {
  description = "Self link of the VPC network to attach firewall rules to."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range of the subnet, used for internal traffic rules."
  type        = string
}

variable "ssh_source_ranges" {
  description = "Source IP ranges allowed to reach instances via SSH."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
