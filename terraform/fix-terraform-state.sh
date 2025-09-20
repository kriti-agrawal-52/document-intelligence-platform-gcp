#!/bin/bash

# Fix Terraform State by Importing Existing Resources
# This script imports existing GCP resources into Terraform state

set -e

echo "🔄 Importing existing GCP resources into Terraform state..."

# Set required environment variables (use dummy values for import)
export TF_VAR_openai_api_key="dummy-for-import"
export TF_VAR_jwt_secret_key="dummy-for-import" 
export TF_VAR_mysql_password="dummy-for-import"

PROJECT_ID="doc-intelligence-1758210325"

# Initialize Terraform first
echo "🔧 Initializing Terraform..."
terraform init

echo "📦 Importing existing resources..."

# Import VPC Network
echo "📡 Importing VPC network..."
terraform import google_compute_network.vpc projects/$PROJECT_ID/global/networks/document-intelligence-vpc || echo "⚠️ VPC import failed or already imported"

# Import Service Account
echo "🔑 Importing GKE Workload Identity service account..."
terraform import google_service_account.gke_workload_identity projects/$PROJECT_ID/serviceAccounts/document-intelligence-gke-wi@$PROJECT_ID.iam.gserviceaccount.com || echo "⚠️ Service account import failed"

# Import Artifact Registry
echo "📦 Importing Artifact Registry..."
terraform import google_artifact_registry_repository.container_registry projects/$PROJECT_ID/locations/asia-south1/repositories/document-intelligence-containers || echo "⚠️ Artifact Registry import failed"

# Import Secrets
echo "🔐 Importing Secret Manager secrets..."
terraform import google_secret_manager_secret.openai_key projects/$PROJECT_ID/secrets/openai-api-key || echo "⚠️ OpenAI secret import failed"
terraform import google_secret_manager_secret.jwt_key projects/$PROJECT_ID/secrets/jwt-secret-key || echo "⚠️ JWT secret import failed"
terraform import google_secret_manager_secret.mysql_password projects/$PROJECT_ID/secrets/mysql-password || echo "⚠️ MySQL secret import failed"

# Import Pub/Sub Topics
echo "📨 Importing Pub/Sub topics..."
terraform import google_pubsub_topic.summarization_jobs projects/$PROJECT_ID/topics/summarization-jobs || echo "⚠️ Summarization topic import failed"
terraform import google_pubsub_topic.summarization_jobs_dlq projects/$PROJECT_ID/topics/summarization-jobs-dlq || echo "⚠️ DLQ topic import failed"

echo "✅ Import process completed!"
echo "📋 Run 'terraform plan' to see remaining changes needed"
