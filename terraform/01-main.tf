# terraform/01-main.tf

# FILE PURPOSE:
# This file is the primary entry point for terraform. It: 
# - configures the cloud provider we are using/interacting with (Google Cloud Platform)
# - Set version constraints for both terraform and the provider plugins to ensure that the code runs predictably and does not break with future updates.
# It does not define any specific resources such as servers or databases, but it sets up the foundational connection and requirements of all other .tf files in the project.

# -- Terraform configuration block -- 
# This block is used to configure Terraform's own behavior.
terraform {
  # `required_version` specifies the minimum version of the Terraform CLI that can be
  # used with this code. This prevents accidental use of an older, incompatible version
  # that might not support the features or syntax used in these files.
  required_version = ">= 1.3.2"

  # Remote state backend - stores state in GCS bucket for persistence across CI/CD runs
  backend "gcs" {
    bucket = "doc-intelligence-terraform-state-bucket"
    prefix = "terraform/state"
  }

  # `required_providers` is a nested block that declares all the cloud providers
  # this project depends on. For each provider, we specify its source and version.
  required_providers {
    # `source` tells Terraform where to download the provider plugin from.
    # "hashicorp/google" is the official Google Cloud provider maintained by HashiCorp.
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # Random provider for generating unique identifiers
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    # --- Kubernetes Provider ---
    # This provider allows Terraform to interact with the Kubernetes API to manage
    # resources like ConfigMaps, Deployments, etc.
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    # --- Helm Provider ---
    # This provider allows Terraform to install Helm charts in the Kubernetes cluster
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# --- Provider Configuration Block ---
# This block configures the specifics for Google Cloud Platform
provider "google" {
  # The GCP project ID where all resources will be created
  project = var.gcp_project_id
  # The GCP region where resources will be deployed
  region = var.gcp_region
}

# Data source to get GCP project information
data "google_project" "current" {}

# Configure Kubernetes provider to connect to our GKE cluster
provider "kubernetes" {
  host                   = "https://${google_container_cluster.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth.0.cluster_ca_certificate)
}

# Configure Helm provider to connect to our GKE cluster
provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth.0.cluster_ca_certificate)
  }
}

# Data source for GCP client configuration
data "google_client_config" "default" {}