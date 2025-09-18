# =============================================================================
# USER IMAGES STORAGE - GOOGLE CLOUD STORAGE BUCKET FOR UPLOADED DOCUMENTS
# =============================================================================
#
# PURPOSE: Store user-uploaded images (documents) securely with metadata
# SECURITY: Private bucket with proper IAM access controls
# METADATA: Each image includes user_id and image_name for tracking
# ARCHITECTURE: Images stored in GCS → Firestore references GCS URLs
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

# STEP 2: Create GCS bucket for user-uploaded images (replaces AWS S3)
resource "google_storage_bucket" "user_images_bucket" {
  name     = "${var.project_name}-user-images-${random_string.user_images_bucket_suffix.result}"
  location = var.gcp_region

  # Enable versioning for image backup and rollback (equivalent to AWS S3 versioning)
  versioning {
    enabled = true
  }

  # Lifecycle management for cost optimization (equivalent to AWS S3 lifecycle rules)
  lifecycle_rule {
    # Delete old versions after 30 days
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
    # Move to Nearline storage after 30 days (equivalent to AWS S3 Standard-IA)
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    # Delete objects after 1 year (equivalent to AWS S3 expiration)
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  # CORS configuration for frontend access (equivalent to AWS S3 CORS)
  cors {
    origin          = ["http://localhost:3000", "http://localhost:3001", "https://*.run.app"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3000
  }

  # Uniform bucket-level access (recommended for security)
  uniform_bucket_level_access = true

  # Public access prevention (equivalent to AWS S3 Block Public Access)
  public_access_prevention = "enforced"

  # Labels for organization (equivalent to AWS S3 tags)
  labels = {
    name        = "${var.project_name}-user-images"
    environment = var.environment
    purpose     = "user-uploaded-document-images"
    region      = var.gcp_region
    backup      = "enabled"
    data-type   = "user-content"
  }

  depends_on = [google_project_service.storage]
}

# STEP 3: IAM Bindings for Bucket Access (equivalent to AWS S3 bucket policy)
# Allow the GKE workload identity service account to read/write objects
resource "google_storage_bucket_iam_binding" "user_images_object_admin" {
  bucket = google_storage_bucket.user_images_bucket.name
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${google_service_account.gke_workload_identity.email}",
  ]
}

# Allow compute service account access (for GKE nodes)
resource "google_storage_bucket_iam_binding" "user_images_compute_access" {
  bucket = google_storage_bucket.user_images_bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
  ]
}
