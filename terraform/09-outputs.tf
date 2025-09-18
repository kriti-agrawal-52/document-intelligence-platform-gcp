# /terraform/09-outputs.tf
#
# FILE PURPOSE:
# This file declares all the output values for our Terraform project. After Terraform
# successfully creates or updates the infrastructure, it will print these values to the
# console. Outputs are a way to expose important information about the resources we've
# created, such as server IP addresses, database endpoints, or resource names.
# This is extremely useful for configuring other systems (like our Kubernetes manifests)
# or for simply connecting to the resources after they are created.

# --- VPC Output ---
# This output exposes the unique ID of the VPC we created.
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = google_compute_network.vpc.id
}

# --- GKE Cluster Outputs ---
# This output provides the API server endpoint for our GKE cluster. We use this URL
# to configure `kubectl` to communicate with our cluster.
output "gke_cluster_endpoint" {
  description = "The endpoint for the GKE cluster."
  value       = google_container_cluster.gke.endpoint
}

# This output provides the name of the GKE cluster.
output "gke_cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.gke.name
}

# This output provides the location of the GKE cluster.
output "gke_cluster_location" {
  description = "The location of the GKE cluster."
  value       = google_container_cluster.gke.location
}

# --- Database Outputs ---
# This output provides the connection endpoint for our Cloud SQL MySQL instance.
# Our application will use this hostname to connect to the database.
output "mysql_connection_name" {
  description = "The connection name of the Cloud SQL MySQL instance."
  value       = google_sql_database_instance.mysql_instance.connection_name
}

output "mysql_private_ip" {
  description = "The private IP address of the Cloud SQL MySQL instance."
  value       = google_sql_database_instance.mysql_instance.private_ip_address
}

# This output provides information about the Firestore database.
output "firestore_database_name" {
  description = "The name of the Firestore database."
  value       = google_firestore_database.document_db.name
}

# --- Redis Cache Output ---
# This output provides the connection endpoint for our Memorystore Redis instance.
output "redis_host" {
  description = "The host address of the Memorystore Redis instance."
  value       = google_redis_instance.cache.host
}

output "redis_port" {
  description = "The port of the Memorystore Redis instance."
  value       = google_redis_instance.cache.port
}

# --- Artifact Registry Repository Output ---
# This output provides the full URL for our Artifact Registry repository. We need this
# URL to tag and push our Docker images.
output "container_registry_url" {
  description = "The URL of the Artifact Registry repository for container images."
  value       = "${google_artifact_registry_repository.container_registry.location}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.container_registry.repository_id}"
}

# --- Pub/Sub Topic Outputs ---
# This output provides the name of our Pub/Sub topic. Our producer and consumer
# applications will use this to interact with the message queue.
output "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic for summarization jobs."
  value       = google_pubsub_topic.summarization_jobs.name
}

output "pubsub_subscription_name" {
  description = "The name of the Pub/Sub subscription for summarization jobs."
  value       = google_pubsub_subscription.summarization_jobs_subscription.name
}

# --- User Images Cloud Storage Bucket Outputs ---
# These outputs provide information about the Cloud Storage bucket used for storing user-uploaded images.
# The text extraction service uses this bucket to store document images securely.
output "user_images_bucket_name" {
  description = "Name of the Cloud Storage bucket for user uploaded images"
  value       = google_storage_bucket.user_images_bucket.name
}

output "user_images_bucket_url" {
  description = "URL of the Cloud Storage bucket for user uploaded images"
  value       = google_storage_bucket.user_images_bucket.url
}

output "user_images_bucket_region" {
  description = "Region where user images are stored"
  value       = var.gcp_region
}

# --- Service Account Output ---
# This output provides the email of the workload identity service account
output "workload_identity_service_account_email" {
  description = "Email of the workload identity service account"
  value       = google_service_account.gke_workload_identity.email
}

# --- Project Information ---
output "gcp_project_id" {
  description = "The GCP project ID"
  value       = var.gcp_project_id
}

output "gcp_region" {
  description = "The GCP region"
  value       = var.gcp_region
}