#!/bin/bash

# GCP Setup Script for Document Intelligence Platform
# Run this after enabling billing for your project

set -e

PROJECT_ID="doc-intelligence-1758210325"

echo "🚀 Setting up GCP project: $PROJECT_ID"
echo ""

# Set the project
gcloud config set project $PROJECT_ID

echo "📡 Enabling required APIs..."
echo ""

# Enable APIs in groups to avoid timeouts
echo "1/4 Enabling compute and container APIs..."
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  artifactregistry.googleapis.com

echo "2/4 Enabling database APIs..."
gcloud services enable \
  sql-component.googleapis.com \
  sqladmin.googleapis.com \
  firestore.googleapis.com \
  redis.googleapis.com

echo "3/4 Enabling storage and messaging APIs..."
gcloud services enable \
  storage-component.googleapis.com \
  storage.googleapis.com \
  pubsub.googleapis.com

echo "4/4 Enabling security and management APIs..."
gcloud services enable \
  secretmanager.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  servicenetworking.googleapis.com

echo ""
echo "✅ All APIs enabled successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Generate OpenAI API key: https://platform.openai.com/api-keys"
echo "2. Generate a JWT secret key (run: openssl rand -base64 32)"
echo "3. Create terraform.tfvars file with your secrets"
echo ""
echo "🎉 Your GCP project is ready for deployment!"
