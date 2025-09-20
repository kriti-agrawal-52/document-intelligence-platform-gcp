# /terraform/07-secrets.tf

# FILE PURPOSE:
# This file manages application secrets using Google Secret Manager.
# It is a critical security best practice to NEVER hardcode sensitive information like
# database passwords or API keys directly in your code. This file creates "secrets" in
# a secure, managed vault. Our application and other Terraform files can then reference
# these secrets by name, without ever exposing the actual secret values in the codebase.

# Secret Manager temporarily disabled - using GitHub Secrets for CI/CD simplicity
# resource "google_project_service" "secret_manager" {
#   service = "secretmanager.googleapis.com"
# }

# Secret Manager resources temporarily disabled - using GitHub Secrets for CI/CD simplicity
# This saves cost (~$1/month) and reduces complexity while maintaining same security level

# # --- OpenAI API Key Secret ---
# resource "google_secret_manager_secret" "openai_key" {
#   secret_id = "openai-api-key"
#   replication {
#     user_managed {
#       replicas {
#         location = var.gcp_region
#       }
#     }
#   }
#   depends_on = [google_project_service.secret_manager]
# }

# resource "google_secret_manager_secret_version" "openai_key" {
#   secret      = google_secret_manager_secret.openai_key.id
#   secret_data = var.openai_api_key
# }

# # --- JWT Secret Key ---
# resource "google_secret_manager_secret" "jwt_key" {
#   secret_id = "jwt-secret-key"
#   replication {
#     user_managed {
#       replicas {
#         location = var.gcp_region
#       }
#     }
#   }
#   depends_on = [google_project_service.secret_manager]
# }

# resource "google_secret_manager_secret_version" "jwt_key" {
#   secret      = google_secret_manager_secret.jwt_key.id
#   secret_data = var.jwt_secret_key
# }

# # --- MySQL Password Secret ---
# resource "google_secret_manager_secret" "mysql_password" {
#   secret_id = "mysql-password"
#   replication {
#     user_managed {
#       replicas {
#         location = var.gcp_region
#       }
#     }
#   }
#   depends_on = [google_project_service.secret_manager]
# }

# resource "google_secret_manager_secret_version" "mysql_password" {
#   secret      = google_secret_manager_secret.mysql_password.id
#   secret_data = var.mysql_password
# }

# # --- IAM bindings for secret access ---
# resource "google_secret_manager_secret_iam_binding" "openai_key_access" {
#   secret_id = google_secret_manager_secret.openai_key.secret_id
#   role      = "roles/secretmanager.secretAccessor"
#   members = [
#     "serviceAccount:${google_service_account.gke_workload_identity.email}"
#   ]
# }

# resource "google_secret_manager_secret_iam_binding" "jwt_key_access" {
#   secret_id = google_secret_manager_secret.jwt_key.secret_id
#   role      = "roles/secretmanager.secretAccessor"
#   members = [
#     "serviceAccount:${google_service_account.gke_workload_identity.email}"
#   ]
# }

# resource "google_secret_manager_secret_iam_binding" "mysql_password_access" {
#   secret_id = google_secret_manager_secret.mysql_password.secret_id
#   role      = "roles/secretmanager.secretAccessor"
#   members = [
#     "serviceAccount:${google_service_account.gke_workload_identity.email}"
#   ]
# }