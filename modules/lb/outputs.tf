output "lb_ip_address" {
  description = "Global static IP address of the load balancer."
  value       = google_compute_global_address.this.address
}

output "lb_url" {
  description = "HTTP URL of the load balancer."
  value       = "http://${google_compute_global_address.this.address}"
}

output "backend_service_self_link" {
  description = "Self link of the backend service."
  value       = google_compute_backend_service.this.self_link
}

output "backend_service_id" {
  description = "ID of the backend service."
  value       = google_compute_backend_service.this.id
}

output "health_check_self_link" {
  description = "Self link of the backend health check."
  value       = google_compute_health_check.lb.self_link
}

output "url_map_self_link" {
  description = "Self link of the URL map."
  value       = google_compute_url_map.this.self_link
}

output "target_http_proxy_self_link" {
  description = "Self link of the target HTTP proxy."
  value       = google_compute_target_http_proxy.this.self_link
}

output "forwarding_rule_self_link" {
  description = "Self link of the global forwarding rule."
  value       = google_compute_global_forwarding_rule.this.self_link
}
