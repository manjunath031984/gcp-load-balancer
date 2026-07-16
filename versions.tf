# =============================================================================
# Terraform & Provider Version Constraints
#
# Providers are Go binaries and inherit the TLS stack of the Go toolchain
# they were built with. Pinning to an unnecessarily old provider release
# can leave you on a build predating full TLS 1.3 support. The floor below
# is raised to a release known to negotiate TLS 1.2/1.3 correctly against
# storage.googleapis.com, while the ceiling avoids an untested major
# version bump (6.x -> 7.x contains breaking resource changes).
# =============================================================================

terraform {
  required_version = ">= 1.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.30, < 7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.30, < 7.0"
    }
  }
}
