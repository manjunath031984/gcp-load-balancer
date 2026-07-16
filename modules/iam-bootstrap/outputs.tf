output "granted_predefined_roles" {
  description = "Predefined roles granted to the deployer service account (empty if use_custom_role = true)."
  value       = [for r in google_project_iam_member.predefined : r.role]
}

output "custom_role_id" {
  description = "Fully-qualified ID of the custom role (null if use_custom_role = false)."
  value       = var.use_custom_role ? google_project_iam_custom_role.terraform_deployer[0].id : null
}
