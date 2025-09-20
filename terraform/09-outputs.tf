# /terraform/09-outputs.tf

# FILE PURPOSE:
# This file defines output values that can be used by other Terraform configurations
# or displayed after deployment. These outputs provide key information about the
# created resources like endpoints, URLs, and connection details.

# --- GKE Cluster Information ---
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.gke.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.gke.endpoint
  sensitive   = true
}

output "gke_cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.gke.location
}

# --- Database Endpoints ---
output "mysql_connection_name" {
  description = "Connection name for Cloud SQL MySQL instance"
  value       = google_sql_database_instance.mysql_instance.connection_name
}

output "mysql_private_ip" {
  description = "Private IP address of the MySQL instance"
  value       = google_sql_database_instance.mysql_instance.private_ip_address
}

# output "firestore_database_name" {
#   description = "Name of the Firestore database"
#   value       = google_firestore_database.document_db.name
# }

# --- Redis Cache Information ---
output "redis_host" {
  description = "Host address of the Redis instance"
  value       = google_redis_instance.cache.host
}

output "redis_port" {
  description = "Port of the Redis instance"
  value       = google_redis_instance.cache.port
}

# --- Artifact Registry Information ---
output "artifact_registry_repository" {
  description = "URL of the Artifact Registry repository"
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.container_registry.repository_id}"
}

# --- Networking Information ---
output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = google_compute_subnetwork.private_subnet.name
}

# --- Pub/Sub Information ---
output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic for summarization jobs"
  value       = google_pubsub_topic.summarization_jobs.name
}

output "pubsub_subscription_name" {
  description = "Name of the Pub/Sub subscription for summarization jobs"
  value       = google_pubsub_subscription.summarization_jobs_subscription.name
}

# --- Storage Information ---
output "user_images_bucket_name" {
  description = "Name of the Cloud Storage bucket for user images"
  value       = google_storage_bucket.user_images_bucket.name
}

# --- Project Information ---
output "gcp_project_id" {
  description = "GCP Project ID"
  value       = var.gcp_project_id
}

output "gcp_region" {
  description = "GCP Region"
  value       = var.gcp_region
}