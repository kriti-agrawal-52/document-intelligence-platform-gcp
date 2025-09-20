# Terraform State Bucket
# This bucket stores Terraform state remotely for persistence across CI/CD runs

resource "google_storage_bucket" "terraform_state" {
  name     = "doc-intelligence-terraform-state-bucket"
  location = "asia-south1"
  
  # Prevent accidental deletion of state
  force_destroy = false
  
  # Enable versioning for state backup
  versioning {
    enabled = true
  }
  
  # Lifecycle management for old state versions
  lifecycle_rule {
    condition {
      age                   = 30
      with_state           = "ARCHIVED"
      num_newer_versions   = 5
    }
    action {
      type = "Delete"
    }
  }
  
  # Security settings
  uniform_bucket_level_access = true
  public_access_prevention = "enforced"
  
  labels = {
    purpose = "terraform-state"
    environment = "all"
  }
}
