# /terraform/04-gke.tf
#
# FILE PURPOSE:
# This file is responsible for provisioning the Google Kubernetes Engine (GKE) cluster.
# GKE is a managed Kubernetes service that simplifies running containerized applications.
# This file defines the Kubernetes control plane (managed by GCP) and the worker nodes
# where our application pods will actually run.

# --- GKE Cluster ---
# We create a GKE cluster with autopilot mode for simplified management
resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.gcp_region

  # Network configuration
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.private_subnet.name

  # Enable Autopilot for simplified management
  enable_autopilot = true

  # IP allocation policy for secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Network policy is automatically enabled in Autopilot mode

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"

    master_global_access_config {
      enabled = true
    }
  }

  # Workload Identity for secure access to GCP services
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Release channel for automatic updates
  release_channel {
    channel = "REGULAR"
  }

  # Addons are automatically configured in Autopilot mode

  # Logging and monitoring
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS"
    ]
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS"
    ]

    managed_prometheus {
      enabled = true
    }
  }

  # Deletion protection
  deletion_protection = false

  # Initial node count (required but ignored in Autopilot)
  initial_node_count = 1
}

# --- Service Account for Workload Identity ---
# This allows pods to authenticate to GCP services
resource "google_service_account" "gke_workload_identity" {
  account_id   = "${var.project_name}-gke-wi"
  display_name = "GKE Workload Identity Service Account"
  description  = "Service account for GKE workload identity"
}

# Bind the service account to the Kubernetes service account
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.gke_workload_identity.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gcp_project_id}.svc.id.goog[default/default]",
    "serviceAccount:${var.gcp_project_id}.svc.id.goog[kube-system/default]"
  ]
}