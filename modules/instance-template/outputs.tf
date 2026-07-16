output "self_link" {
  description = "Self link of the instance template."
  value       = google_compute_instance_template.this.self_link
}

output "id" {
  description = "ID of the instance template."
  value       = google_compute_instance_template.this.id
}

output "name" {
  description = "Name of the instance template."
  value       = google_compute_instance_template.this.name
}
