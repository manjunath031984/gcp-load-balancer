output "enabled_apis" {
  description = "List of APIs enabled on the project."
  value       = [for api in google_project_service.this : api.service]
}
