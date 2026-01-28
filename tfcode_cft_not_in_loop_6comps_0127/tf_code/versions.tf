terraform {
  # This block specifies the required Terraform version and provider versions
  # for this module.
  required_version = ">= 1.0"

  required_providers {
    # The Google Provider is used to manage Google Cloud resources.
    google = {
      source  = "hashicorp/google"
      version = ">= 4.40.0"
    }
    # The Google Beta Provider is used for features that are not yet generally available.
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.40.0"
    }
  }
}
