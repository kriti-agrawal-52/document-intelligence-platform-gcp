# =============================================================================
# USER IMAGES STORAGE - CLOUD STORAGE BUCKET FOR UPLOADED DOCUMENTS
# =============================================================================
#
# PURPOSE: Store user-uploaded images (documents) securely with metadata
# SECURITY: Private bucket with IAM-based access control
# METADATA: Each image includes user_id and image_name for tracking
# ARCHITECTURE: Images stored in Cloud Storage → Firestore references Cloud Storage URLs
#
# STORAGE PATTERN:
# /user-images/{user_id}/{image_name}_{timestamp}.{extension}
# EXAMPLE: /user-images/123/document_20241201_143022.jpg
# =============================================================================

# Enable Cloud Storage API
resource "google_project_service" "storage" {
  service = "storage.googleapis.com"
}

# STEP 1: Create a unique suffix for the user images bucket
resource "random_string" "user_images_bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# STEP 2: Create Cloud Storage bucket for user-uploaded images
resource "google_storage_bucket" "user_images_bucket" {
  name     = "${var.project_name}-user-images-${random_string.user_images_bucket_suffix.result}"
  location = var.gcp_region

  # Prevent deletion when bucket is not empty
  force_destroy = true

  # Versioning for backup and rollback
  versioning {
    enabled = true
  }

  # Lifecycle management for cost optimization
  lifecycle_rule {
    condition {
      age = 365 # 1 year
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age                   = 30
      with_state           = "ARCHIVED"
      num_newer_versions   = 3
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # CORS configuration for frontend access
  cors {
    origin          = ["http://localhost:3000", "http://localhost:3001", "https://*.run.app"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3000
  }

  # Encryption is Google-managed by default (no explicit configuration needed)

  # Public access prevention
  public_access_prevention = "enforced"

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  labels = {
    environment = var.environment
    purpose     = "user-uploaded-document-images"
    backup      = "enabled"
    data-type   = "user-content"
  }

  depends_on = [google_project_service.storage]
}

# STEP 3: IAM binding for GKE workload identity to access bucket
resource "google_storage_bucket_iam_binding" "user_images_object_admin" {
  bucket = google_storage_bucket.user_images_bucket.name
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${google_service_account.gke_workload_identity.email}"
  ]
}

# Allow read access for the compute service account (for GKE nodes)
resource "google_storage_bucket_iam_binding" "user_images_compute_access" {
  bucket = google_storage_bucket.user_images_bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
  ]
}
