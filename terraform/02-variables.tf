# /terraform/02-variables.tf

# FILE PURPOSE:
# Dedicated to declaring all the input variables for the terraform project.
# Using variables makes our code reusable and configurable without needing to change the core resource definitions.
# We can provide different values for these variables at runtime or define default values.

# -- GCP Project ID Variable --
variable "gcp_project_id" {
  description = "The GCP project ID where resources will be deployed"
  type        = string
  default     = "doc-intelligence-1758210325"
}

# -- GCP Region Variable --
variable "gcp_region" {
  description = "The GCP region to deploy the resources in"
  type        = string
  default     = "asia-south1"
}

# -- VPC CIDR Block Variable -- 
# This variable defines the main IP address range for our Virtual Private Cloud (VPC).
variable "vpc_cidr" {
  description = "The CIDR block for VPC"
  type        = string
  # The "10.0.0.0/16" range provides 65,536 private IP addresses, which is a common
  # standard for a new VPC, offering plenty of room for subnets and resources.
  default = "10.0.0.0/16"
}

# -- GKE Cluster Name Variable --
# This variable defines the name of our GKE cluster. It's used in various
# resource tags and naming conventions throughout the infrastructure.
variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "doc-intel-gke"
}

# -- Project Name Variable --
variable "project_name" {
  description = "The name of the project, used for resource naming"
  type        = string
  default     = "document-intelligence"
}

# -- Environment Variable --
variable "environment" {
  description = "The deployment environment (e.g., dev, staging, production)"
  type        = string
  default     = "dev"
}

# -- Secrets Variables --
# These variables should be provided at runtime and never committed to version control
variable "openai_api_key" {
  description = "OpenAI API Key for text extraction and summarization services"
  type        = string
  sensitive   = true
  # No default value - must be provided via environment variable or terraform.tfvars
}

variable "jwt_secret_key" {
  description = "Secret key for JWT token signing"
  type        = string
  sensitive   = true
  # No default value - must be provided via environment variable or terraform.tfvars
}

variable "mysql_password" {
  description = "Password for the MySQL database"
  type        = string
  sensitive   = true
  # No default value - must be provided via environment variable or terraform.tfvars
}