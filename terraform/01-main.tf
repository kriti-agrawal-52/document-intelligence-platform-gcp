# terraform/01-main.tf

# FILE PURPOSE:
# This file is the primary entry point for terraform. It: 
# - configures the cloud provider we are using/interacting with (in this case Google Cloud Platform)
# - Set version constraints for both terraform and the provider plugins to ensure that the code runs predictably and does not break with future updates.
# It does not define any specific resources such as servers or databases, but it sets up the foundational connection and requirements of all other .tf files in the project.

# -- Terraform configuration block -- 
# This block is used to configure Terraform's own behavior.
terraform {
  # `required_version` specifies the minimum version of the Terraform CLI that can be
  # used with this code. This prevents accidental use of an older, incompatible version
  # that might not support the features or syntax used in these files.
  required_version = ">= 1.3.2"

  # `required_providers` is a nested block that declares all the cloud providers
  # this project depends on. For each provider, we specify its source and version.
  required_providers {
    # `source` tells Terraform where to download the provider plugin from.
    # "hashicorp/google" is the official Google Cloud provider maintained by HashiCorp.
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # Google Beta provider for preview features
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    # Random provider for generating unique identifiers
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# --- Provider Configuration Block ---
# This block configures the specifics for the Google Cloud provider.
provider "google" {
  # The `project` argument tells the Google Cloud provider which GCP project to create
  # all the resources in. All resources defined in this project (unless explicitly
  # overridden) will be created in the project specified by this variable.
  project = var.gcp_project_id
  # The `region` argument tells the provider which geographical region to create
  # all the resources in.
  region = var.gcp_region
}

# Google Beta provider for preview features
provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Data source to get GCP project information
data "google_project" "current" {
  project_id = var.gcp_project_id
}
