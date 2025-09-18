#!/bin/bash

# Enable GCP APIs Script for Document Intelligence Platform
# This script enables all the required Google Cloud APIs

set -e

echo "🚀 Enabling required Google Cloud APIs..."

# Core APIs
echo "📡 Enabling core APIs..."
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable artifactregistry.googleapis.com

# Database APIs
echo "🗄️  Enabling database APIs..."
gcloud services enable sql-component.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable redis.googleapis.com

# Storage and Messaging APIs
echo "📦 Enabling storage and messaging APIs..."
gcloud services enable storage-component.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable pubsub.googleapis.com

# Security and Management APIs
echo "🔐 Enabling security and management APIs..."
gcloud services enable secretmanager.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable servicenetworking.googleapis.com

# Monitoring and Logging APIs
echo "📊 Enabling monitoring APIs..."
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com

echo "✅ All APIs enabled successfully!"
echo ""
echo "📋 Enabled APIs:"
echo "   • Compute Engine API"
echo "   • Kubernetes Engine API" 
echo "   • Container Registry API"
echo "   • Artifact Registry API"
echo "   • Cloud SQL Admin API"
echo "   • Firestore API"
echo "   • Memorystore for Redis API"
echo "   • Cloud Storage API"
echo "   • Cloud Pub/Sub API"
echo "   • Secret Manager API"
echo "   • Identity and Access Management API"
echo "   • Cloud Resource Manager API"
echo "   • Service Networking API"
echo "   • Cloud Monitoring API"
echo "   • Cloud Logging API"
echo ""
echo "🎉 Your GCP project is ready for deployment!"
