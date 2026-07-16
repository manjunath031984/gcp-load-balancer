# GCP Global HTTP Load Balancer — Terraform + Jenkins

Production-ready, modular Terraform project that provisions a **Global External HTTP Application Load Balancer** fronting a **Regional Managed Instance Group** of Apache web servers on Google Cloud Platform, plus a declarative Jenkins pipeline for CI/CD.

## Architecture

```
Internet
   │
   ▼
Global Forwarding Rule (Global Static IP, port 80)
   │
   ▼
Target HTTP Proxy
   │
   ▼
URL Map
   │
   ▼
Backend Service  ◄── Health Check (HTTP)
   │
   ▼
Regional Managed Instance Group (2 x e2-micro, no autoscaling)
   │  auto-healing via HTTP Health Check
   ▼
Instance Template (Ubuntu 26.04 LTS Minimal, Apache2, 10GB pd-balanced)
   │
   ▼
Custom VPC / Subnet (Private Google Access + Flow Logs)
```

## Project Details

| Item | Value |
|---|---|
| Project ID | `gcp-dev-july-2026` |
| Region | `us-central1` |
| Zone | `us-central1-a` |
| Service Account | `infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com` |
| Terraform Version | `>= 1.13` |
| Image | `ubuntu-os-cloud/ubuntu-minimal-2604-lts-amd64` |
| Machine Type | `e2-micro` |
| Boot Disk | `10 GB pd-balanced` |
| MIG Size | `2` (fixed, no autoscaling) |
| MIG Zones | `us-central1-a`, `us-central1-b` (fixed via `distribution_policy_zones`) |

## Project Structure

```
.
├── Jenkinsfile                  # Declarative CI/CD pipeline
├── README.md
├── .gitignore
├── main.tf                      # Root module — wires all sub-modules together
├── variables.tf                 # Root input variables
├── outputs.tf                   # Root outputs (LB IP, MIG, template, backend, HC)
├── providers.tf                 # google / google-beta provider blocks
├── versions.tf                  # Terraform & provider version constraints
├── backend.tf                   # GCS remote state backend
├── locals.tf                    # Computed local values
├── terraform.tfvars             # Default (dev) variable values
├── environments/
│   └── dev/
│       ├── dev.tfvars           # Environment-specific variable overrides
│       └── backend.hcl          # Partial backend config for `-backend-config`
├── startup-script/
│   └── apache.sh                # Apache2 install + dynamic index.html
└── modules/
    ├── apis/                    # Enables required Google Cloud APIs
    ├── network/                 # Custom VPC, Subnet, Private Google Access, Flow Logs
    ├── firewall/                 # HTTP, HTTPS, SSH, Internal, Health Check rules
    ├── instance-template/        # Compute instance template
    ├── mig/                      # Regional Managed Instance Group + auto-healing
    ├── lb/                       # Global External HTTP Load Balancer
    └── iam-bootstrap/            # Standalone, admin-run IAM grant for the deployer SA (NOT wired into main.tf)
```

## Modules

### `modules/apis`
Enables required project APIs (`compute`, `iam`, `cloudresourcemanager`, `servicenetworking`, `logging`, `monitoring`, etc.) via `google_project_service`. Controlled by the root `manage_apis` variable (default `true`) — set `manage_apis = false` if the deploying service account lacks `serviceusage.services.enable`/`list` and the APIs are already enabled by an admin out-of-band.

### `modules/network`
- Custom-mode VPC (`auto_create_subnetworks = false`)
- Regional subnet with **Private Google Access** enabled
- **VPC Flow Logs** enabled on the subnet (5s aggregation interval, full metadata)

### `modules/firewall`
- `allow-http` — TCP/80 from `0.0.0.0/0`, tag `http-server`
- `allow-https` — TCP/443 from `0.0.0.0/0`, tag `https-server`
- `allow-ssh` — TCP/22 from configurable source ranges, tag `ssh-allowed`
- `allow-internal` — all protocols within the subnet CIDR
- `allow-health-checks` — TCP/80,443 from Google's health-check ranges `130.211.0.0/22` and `35.191.0.0/16`

### `modules/instance-template`
- Ubuntu 26.04 LTS Minimal (`ubuntu-os-cloud/ubuntu-minimal-2604-lts-amd64`)
- `e2-micro`, 10 GB `pd-balanced` boot disk
- Service account `infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com` scoped to `cloud-platform`
- `metadata_startup_script` sourced from [`startup-script/apache.sh`](startup-script/apache.sh)
- `create_before_destroy` lifecycle for safe template rotation

### `modules/mig`
- `google_compute_region_instance_group_manager` with **fixed `target_size = 2`** — **no autoscaler resource is created**
- Pinned to a fixed set of zones via `distribution_policy_zones` (default `us-central1-a`, `us-central1-b`)
- `update_policy.max_surge_fixed` is derived from `length(distribution_policy_zones)` (with `max_unavailable_fixed = 0`), which is required because GCP rejects percent-based maxSurge/maxUnavailable for regional MIGs with `target_size < 10`, and fixed values must equal `0` or at least the number of zones the MIG spans
- Dedicated auto-healing `google_compute_health_check` (HTTP) with configurable initial delay
- Named port `http:80` for load balancer backend attachment

### `modules/iam-bootstrap`
Standalone Terraform root (separate state, **not** wired into the root `main.tf`) that grants the deploying service account either a curated set of predefined roles or a least-privilege custom role. Must be applied manually by a project Owner/IAM Admin — the deploying SA must never be able to grant itself additional IAM permissions. See the usage instructions in [`modules/iam-bootstrap/main.tf`](modules/iam-bootstrap/main.tf).

### `modules/lb`
Full Global External HTTP Application Load Balancer chain:
`google_compute_health_check` → `google_compute_backend_service` → `google_compute_url_map` → `google_compute_target_http_proxy` → `google_compute_global_address` → `google_compute_global_forwarding_rule`

## Startup Script

[`startup-script/apache.sh`](startup-script/apache.sh) installs Apache2 and generates `/var/www/html/index.html` displaying the **Project ID, Hostname, Instance Name, Zone, Date, and Time**, sourced from the GCE metadata server.

## Remote State Backend

State is stored in GCS:

```hcl
terraform {
  backend "gcs" {
    bucket = "gcp-dev-july-2026-terraform-state"
    prefix = "alb/dev"
  }
}
```

Create the bucket once, before the first `terraform init` (requires versioning + uniform bucket-level access for production use):

```bash
gsutil mb -p gcp-dev-july-2026 -l us-central1 gs://gcp-dev-july-2026-terraform-state
gsutil versioning set on gs://gcp-dev-july-2026-terraform-state
gsutil ubla set on gs://gcp-dev-july-2026-terraform-state
```

## Prerequisites

1. Terraform `>= 1.13`
2. A GCP service account key (or Workload Identity) for `infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com` with roles:
   - `roles/compute.admin`
   - `roles/iam.serviceAccountUser`
   - `roles/servicenetworking.networksAdmin`
   - `roles/storage.admin` (on the state bucket)
   - `roles/serviceusage.serviceUsageAdmin`
3. Authenticate locally:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/infra-admin-key.json"
   ```

> The IAM roles above are granted by a project Owner/Admin running [`modules/iam-bootstrap`](modules/iam-bootstrap) directly (predefined roles, or a least-privilege custom role via `-var="use_custom_role=true"`) \u2014 never by the deploying service account itself, and never through the main pipeline/root module.
>
> If `serviceusage.services.enable`/`list` is not yet granted, set `manage_apis = false` in your `.tfvars` to skip the `modules/apis` API-enablement step until an admin enables the required APIs out-of-band.

## Usage

```bash
# Initialize (downloads providers, configures GCS backend)
terraform init

# Format & validate
terraform fmt -recursive
terraform validate

# Plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"

# Destroy
terraform destroy -var-file="terraform.tfvars"
```

To target the `dev` environment file explicitly:

```bash
terraform init -backend-config="environments/dev/backend.hcl"
terraform plan -var-file="environments/dev/dev.tfvars"
```

## Outputs

| Output | Description |
|---|---|
| `load_balancer_ip` | Global static IP of the HTTP load balancer |
| `load_balancer_url` | `http://<load_balancer_ip>` |
| `backend_service_self_link` | Self link of the LB backend service |
| `health_check_self_link` | Self link of the LB health check |
| `managed_instance_group_self_link` | Self link of the regional MIG |
| `managed_instance_group_name` | Name of the regional MIG |
| `instance_template_self_link` | Self link of the compute instance template |
| `instance_template_name` | Name of the compute instance template |
| `network_self_link` | Self link of the VPC network |
| `subnet_self_link` | Self link of the subnet |

After `terraform apply`, verify with:

```bash
curl "$(terraform output -raw load_balancer_url)"
```

> Note: it can take a few minutes for backend instances to pass health checks after the first apply.

## Jenkins Pipeline

The [`Jenkinsfile`](Jenkinsfile) implements a single, self-contained declarative pipeline (no Docker, no external scripts):

1. **Checkout Source Code** — pulls the repository via `checkout scm`.
2. **Authenticate to GCP** — materializes the service account JSON from the Jenkins credential `gcp-sa-key` (Secret file) into `GOOGLE_APPLICATION_CREDENTIALS` and runs `gcloud auth activate-service-account`.
3. **Terraform Format** — `terraform fmt -check -recursive -diff`.
4. **Terraform Init** — `terraform init -input=false -no-color`.
5. **Terraform Validate** — `terraform validate -no-color`.
6. **Terraform Plan** — generates `tfplan.out`/`tfplan.log` (only when `ACTION == apply`).
7. **Manual Approval before Apply** — pipeline `input` step gates the apply (only when `ACTION == apply`).
8. **Terraform Apply** — `terraform apply -auto-approve tfplan.out` (piped through `set -euo pipefail` so a failed apply fails the build).
9. **Manual Approval before Destroy** — pipeline `input` step gates the destroy (only when `ACTION == destroy`).
10. **Terraform Destroy** — `terraform destroy -auto-approve -var-file=...` (only when `ACTION == destroy`).
11. **Display Terraform Outputs** — prints all outputs, only reached after a successful apply.
12. **Workspace Cleanup** — removes the local `.terraform` directory.
13. **Post** — `always` archives `tfplan.out`, `tfplan.log`, `tfapply.log`, `tfdestroy.log`, `tfoutputs.log`; `failure` forces the build result to `FAILURE`; `cleanup` wipes the workspace.

### Required Jenkins Configuration

| Item | Type | Value |
|---|---|---|
| Credential ID | Secret file | `gcp-sa-key` — JSON key for `infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com` |
| Pipeline parameter | Choice | `ACTION` — `apply` or `destroy` |
| Pipeline parameter | String | `TF_WORKING_DIR` — defaults to `.` |
| Pipeline parameter | String | `VAR_FILE` — defaults to `terraform.tfvars` |

### Running a Destroy

Trigger the pipeline with **Build with Parameters** → set `ACTION` to `destroy` → confirm the manual approval gate.

## Security Notes

- The service account JSON key is never committed; it's injected at runtime via Jenkins credentials and deleted in the `post { always }` block.
- SSH access defaults to `0.0.0.0/0` for convenience — restrict `ssh_source_ranges` to known CIDR ranges (e.g., corporate VPN/bastion) before production use.
- Instances only receive the `cloud-platform` OAuth scope with IAM permissions enforced by the service account's bound roles — follow least privilege on the SA itself.
- State bucket should have versioning and uniform bucket-level access enabled, and access restricted to the CI/CD service account and admins.
