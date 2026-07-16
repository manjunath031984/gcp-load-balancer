output "instance_group_self_link" {
  description = "Self link of the regional managed instance group."
  value       = google_compute_region_instance_group_manager.this.instance_group
}

output "mig_id" {
  description = "ID of the regional managed instance group."
  value       = google_compute_region_instance_group_manager.this.id
}

output "mig_name" {
  description = "Name of the regional managed instance group."
  value       = google_compute_region_instance_group_manager.this.name
}

output "autohealing_health_check_self_link" {
  description = "Self link of the auto-healing health check."
  value       = google_compute_health_check.autohealing.self_link
}
