# =============================================================================
# Root Module - GCP Global HTTP Load Balancer with Regional MIG
# =============================================================================

module "apis" {
  source = "./modules/apis"

  project_id    = var.project_id
  activate_apis = var.activate_apis
}

module "network" {
  source = "./modules/network"

  project_id       = var.project_id
  region           = var.region
  network_name     = local.network_name
  subnet_name      = local.subnet_name
  subnet_cidr      = var.subnet_cidr
  enable_flow_logs = var.enable_flow_logs

  depends_on = [module.apis]
}

module "firewall" {
  source = "./modules/firewall"

  project_id        = var.project_id
  name_prefix       = local.name_prefix
  network_self_link = module.network.network_self_link
  subnet_cidr       = var.subnet_cidr
  ssh_source_ranges = var.ssh_source_ranges
}

module "instance_template" {
  source = "./modules/instance-template"

  project_id            = var.project_id
  region                = var.region
  name_prefix           = local.name_prefix
  machine_type          = var.machine_type
  image_project         = var.image_project
  image_family          = var.image_family
  disk_size_gb          = var.disk_size_gb
  disk_type             = var.disk_type
  network_self_link     = module.network.network_self_link
  subnetwork_self_link  = module.network.subnet_self_link
  service_account_email = var.service_account_email
  startup_script        = local.startup_script
  tags                  = var.instance_tags
  labels                = local.common_labels

  depends_on = [module.firewall]
}

module "mig" {
  source = "./modules/mig"

  project_id                     = var.project_id
  region                         = var.region
  name                           = local.mig_name
  base_instance_name             = var.base_instance_name
  instance_template_self_link    = module.instance_template.self_link
  target_size                    = var.target_size
  named_port                     = var.lb_port
  health_check_port              = var.lb_port
  health_check_path              = "/"
  health_check_initial_delay_sec = var.health_check_initial_delay_sec
}

module "lb" {
  source = "./modules/lb"

  project_id               = var.project_id
  name                     = local.lb_name
  instance_group_self_link = module.mig.instance_group_self_link
  backend_port             = var.lb_port
  health_check_path        = "/"
  forwarding_rule_port     = tostring(var.lb_port)
}
