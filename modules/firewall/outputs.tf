output "allow_http_id" {
  description = "ID of the HTTP firewall rule."
  value       = google_compute_firewall.allow_http.id
}

output "allow_https_id" {
  description = "ID of the HTTPS firewall rule."
  value       = google_compute_firewall.allow_https.id
}

output "allow_ssh_id" {
  description = "ID of the SSH firewall rule."
  value       = google_compute_firewall.allow_ssh.id
}

output "allow_internal_id" {
  description = "ID of the internal traffic firewall rule."
  value       = google_compute_firewall.allow_internal.id
}

output "allow_health_checks_id" {
  description = "ID of the Google health check firewall rule."
  value       = google_compute_firewall.allow_health_checks.id
}
