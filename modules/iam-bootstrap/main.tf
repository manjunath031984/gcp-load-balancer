# =============================================================================
# IAM Bootstrap - Least-Privilege Custom Role for the Terraform Deployer SA
#
# WHO RUNS THIS: A project Owner / IAM Admin, using their OWN elevated
# credentials - NOT the `infra-admin` service account, and NOT via the
# Jenkins pipeline.
#
# WHY SEPARATE: The `infra-admin` service account that Jenkins uses to run
# `terraform plan/apply` must NOT be able to grant itself additional IAM
# permissions (that would be a privilege-escalation vector). Granting IAM
# roles is therefore a one-time, admin-run bootstrap step, kept in its own
# Terraform root/state, completely isolated from the application pipeline.
#
# USAGE:
#   cd modules/iam-bootstrap
#   terraform init
#   terraform apply \
#     -var="project_id=gcp-dev-july-2026" \
#     -var="deployer_service_account_email=infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com"
# =============================================================================

terraform {
  required_version = ">= 1.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.30, < 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

# -----------------------------------------------------------------------------
# Option A (recommended, simplest): predefined Google-managed roles.
# These cover every permission this project's resources require:
#   - roles/serviceusage.serviceUsageAdmin : enable/disable/list/get project APIs
#   - roles/compute.networkAdmin           : VPC, subnetworks, firewalls, routes
#   - roles/compute.instanceAdmin.v1       : instance templates, instances, MIGs,
#                                             auto-healing health checks, disks
#   - roles/compute.loadBalancerAdmin      : health checks, backend services,
#                                             URL maps, target proxies, global
#                                             addresses, global forwarding rules
#   - roles/iam.serviceAccountUser         : actAs the SA attached to instances
# -----------------------------------------------------------------------------
locals {
  predefined_roles = var.use_custom_role ? [] : [
    "roles/serviceusage.serviceUsageAdmin",
    "roles/compute.networkAdmin",
    "roles/compute.instanceAdmin.v1",
    "roles/compute.loadBalancerAdmin",
    "roles/iam.serviceAccountUser",
  ]
}

resource "google_project_iam_member" "predefined" {
  for_each = toset(local.predefined_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.deployer_service_account_email}"
}

# -----------------------------------------------------------------------------
# Option B: a single least-privilege custom role, for environments where the
# predefined roles above are considered too broad. Enable with
# -var="use_custom_role=true".
# -----------------------------------------------------------------------------
resource "google_project_iam_custom_role" "terraform_deployer" {
  count = var.use_custom_role ? 1 : 0

  project     = var.project_id
  role_id     = "terraformLbDeployer"
  title       = "Terraform GCP Load Balancer Deployer"
  description = "Minimum permissions required to plan/apply the gcp-load-balancer Terraform stack."
  stage       = "GA"

  permissions = [
    # Service Usage (API enablement)
    "serviceusage.services.enable",
    "serviceusage.services.disable",
    "serviceusage.services.get",
    "serviceusage.services.list",

    # Resource Manager
    "resourcemanager.projects.get",

    # Networking
    "compute.networks.create",
    "compute.networks.get",
    "compute.networks.list",
    "compute.networks.update",
    "compute.networks.delete",
    "compute.subnetworks.create",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.subnetworks.update",
    "compute.subnetworks.delete",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.subnetworks.setPrivateIpGoogleAccess",

    # Firewall
    "compute.firewalls.create",
    "compute.firewalls.get",
    "compute.firewalls.list",
    "compute.firewalls.update",
    "compute.firewalls.delete",

    # Instance templates / instances
    "compute.instanceTemplates.create",
    "compute.instanceTemplates.get",
    "compute.instanceTemplates.list",
    "compute.instanceTemplates.delete",
    "compute.instanceTemplates.useReadOnly",
    "compute.images.useReadOnly",
    "compute.machineTypes.get",
    "compute.machineTypes.list",
    "compute.disks.create",
    "compute.disks.get",
    "compute.disks.list",
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.setMetadata",
    "compute.instances.setTags",
    "compute.instances.setLabels",
    "compute.instances.setServiceAccount",
    "compute.instances.use",

    # Managed instance groups
    "compute.instanceGroups.create",
    "compute.instanceGroups.get",
    "compute.instanceGroups.list",
    "compute.instanceGroups.update",
    "compute.instanceGroups.delete",
    "compute.instanceGroups.use",
    "compute.regionInstanceGroupManagers.create",
    "compute.regionInstanceGroupManagers.get",
    "compute.regionInstanceGroupManagers.list",
    "compute.regionInstanceGroupManagers.update",
    "compute.regionInstanceGroupManagers.delete",
    "compute.regionInstanceGroupManagers.use",

    # Health checks (MIG auto-healing + load balancer)
    "compute.healthChecks.create",
    "compute.healthChecks.get",
    "compute.healthChecks.list",
    "compute.healthChecks.update",
    "compute.healthChecks.delete",
    "compute.healthChecks.use",

    # Load balancer
    "compute.backendServices.create",
    "compute.backendServices.get",
    "compute.backendServices.list",
    "compute.backendServices.update",
    "compute.backendServices.delete",
    "compute.backendServices.use",
    "compute.urlMaps.create",
    "compute.urlMaps.get",
    "compute.urlMaps.list",
    "compute.urlMaps.update",
    "compute.urlMaps.delete",
    "compute.targetHttpProxies.create",
    "compute.targetHttpProxies.get",
    "compute.targetHttpProxies.list",
    "compute.targetHttpProxies.update",
    "compute.targetHttpProxies.delete",
    "compute.targetHttpProxies.use",
    "compute.globalAddresses.create",
    "compute.globalAddresses.get",
    "compute.globalAddresses.list",
    "compute.globalAddresses.delete",
    "compute.globalAddresses.setLabels",
    "compute.globalAddresses.use",
    "compute.globalForwardingRules.create",
    "compute.globalForwardingRules.get",
    "compute.globalForwardingRules.list",
    "compute.globalForwardingRules.update",
    "compute.globalForwardingRules.delete",
    "compute.globalForwardingRules.setLabels",

    # Async compute operation polling (required by nearly every create/update/delete)
    "compute.globalOperations.get",
    "compute.globalOperations.list",
    "compute.regionOperations.get",
    "compute.regionOperations.list",
    "compute.zoneOperations.get",
    "compute.zoneOperations.list",

    # Zone/region/project metadata lookups used by the provider
    "compute.zones.get",
    "compute.zones.list",
    "compute.regions.get",
    "compute.regions.list",
    "compute.projects.get",

    # actAs the service account attached to compute instances
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
  ]
}

resource "google_project_iam_member" "custom" {
  count = var.use_custom_role ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.terraform_deployer[0].id
  member  = "serviceAccount:${var.deployer_service_account_email}"
}
