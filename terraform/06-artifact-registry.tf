# /terraform/06-artifact-registry.tf
#
# FILE PURPOSE:
# This file is responsible for creating the Google Artifact Registry repositories.
# Artifact Registry is a managed Docker container registry service. These repositories
# will securely store the Docker images for our microservices after we build them.
# The GKE cluster will then pull the images from these repositories to run our application pods.

# Enable Artifact Registry API
resource "google_project_service" "artifact_registry" {
  service = "artifactregistry.googleapis.com"
}

# --- Artifact Registry Repository ---
resource "google_artifact_registry_repository" "container_registry" {
  location      = var.gcp_region
  repository_id = "${var.project_name}-containers"
  description   = "Docker container images for Document Intelligence Platform"
  format        = "DOCKER"

  depends_on = [google_project_service.artifact_registry]
}

# --- IAM bindings for GKE to pull images ---
resource "google_artifact_registry_repository_iam_binding" "gke_pull_access" {
  project    = var.gcp_project_id
  location   = google_artifact_registry_repository.container_registry.location
  repository = google_artifact_registry_repository.container_registry.name
  role       = "roles/artifactregistry.reader"

  members = [
    "serviceAccount:${google_service_account.gke_workload_identity.email}",
    "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
  ]
}