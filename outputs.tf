# =============================================================================
# Root Module Outputs
# =============================================================================

# --- Load Balancer -----------------------------------------------------------

output "load_balancer_ip" {
  description = "Global static IP address of the HTTP load balancer."
  value       = module.lb.lb_ip_address
}

output "load_balancer_url" {
  description = "HTTP URL of the load balancer."
  value       = module.lb.lb_url
}

output "backend_service_self_link" {
  description = "Self link of the load balancer backend service."
  value       = module.lb.backend_service_self_link
}

output "health_check_self_link" {
  description = "Self link of the load balancer health check."
  value       = module.lb.health_check_self_link
}

# --- Managed Instance Group --------------------------------------------------

output "managed_instance_group_self_link" {
  description = "Self link of the regional managed instance group."
  value       = module.mig.instance_group_self_link
}

output "managed_instance_group_name" {
  description = "Name of the regional managed instance group."
  value       = module.mig.mig_name
}

# --- Instance Template ---------------------------------------------------

output "instance_template_self_link" {
  description = "Self link of the compute instance template."
  value       = module.instance_template.self_link
}

output "instance_template_name" {
  description = "Name of the compute instance template."
  value       = module.instance_template.name
}

# --- Network -------------------------------------------------------------

output "network_self_link" {
  description = "Self link of the VPC network."
  value       = module.network.network_self_link
}

output "subnet_self_link" {
  description = "Self link of the subnet."
  value       = module.network.subnet_self_link
}
