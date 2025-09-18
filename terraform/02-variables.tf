# /terraform/02-variables.tf

# FILE PURPOSE:
# Dedicated to declaring all the input variables for the terraform project.
# using variables makes our code reusable and configurable without needing to change the core resource definitions.
# We can provide different values for these variables at runtime or define default values. 

# -- GCP Project ID variable --
variable "gcp_project_id" {
  description = "The GCP project ID to deploy resources in."
  type        = string
  # No default value - must be provided via environment variable or terraform.tfvars
}

# -- GCP Region variable --
variable "gcp_region" {
  # The `description` provides helpful context about what the variable is for. This
  # description is shown to the user when they run `terraform plan` or `terraform apply`.
  description = "The GCP region to deploy the resources in."

  # The `type` constraint ensures that the value provided for this variable is a string.
  # This helps prevent errors by enforcing data types.
  type = string

  # The `default` value is used if no other value is provided for this variable when
  # Terraform is run. This makes the variable optional.
  default = "asia-south1"
}

# -- GCP Zones variable --
variable "gcp_zones" {
  description = "The GCP zones to use for multi-zone deployments."
  type        = list(string)
  default     = ["asia-south1-a", "asia-south1-b", "asia-south1-c"]
}

# -- VPC CIDR Block Variable -- 
# This variable defines the main IP address range for our Virtual Private Cloud (VPC).
variable "vpc_cidr" {
  description = "The CIDR block for VPC."
  type        = string
  # The "10.0.0.0/16" range provides 65,536 private IP addresses, which is a common
  # standard for a new VPC, offering plenty of room for subnets and resources.
  default = "10.0.0.0/16"
}

# -- GKE Cluster Name Variable --
# This variable defines the name of our GKE cluster. It's used in various
# resource tags and naming conventions throughout the infrastructure.
variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  default     = "document-intelligence"
}

# -- Project Name Variable --
variable "project_name" {
  description = "The name of the project, used for resource naming."
  type        = string
  default     = "document-intelligence"
}

# -- Environment Variable --
variable "environment" {
  description = "The deployment environment (e.g., dev, staging, production)."
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
  description = "Password for MySQL database user"
  type        = string
  sensitive   = true
  # No default value - must be provided via environment variable or terraform.tfvars
}