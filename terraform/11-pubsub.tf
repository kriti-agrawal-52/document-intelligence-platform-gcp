# /terraform/11-pubsub.tf

# FILE PURPOSE:
# This file creates Google Cloud Pub/Sub topics and subscriptions for asynchronous message processing.
# Pub/Sub is the GCP equivalent of AWS SQS for reliable, scalable messaging.

# Enable Pub/Sub API
resource "google_project_service" "pubsub" {
  service = "pubsub.googleapis.com"
}

# --- Main Topic for Summarization Jobs ---
resource "google_pubsub_topic" "summarization_jobs" {
  name = "summarization-jobs"

  depends_on = [google_project_service.pubsub]
}

# --- Main Subscription for Processing Summarization Jobs ---
resource "google_pubsub_subscription" "summarization_jobs_subscription" {
  name  = "summarization-jobs-subscription"
  topic = google_pubsub_topic.summarization_jobs.name

  # Message retention duration (4 days, equivalent to SQS)
  message_retention_duration = "345600s" # 4 days

  # Acknowledgment deadline (equivalent to visibility timeout)
  ack_deadline_seconds = 300 # 5 minutes

  # Retry policy for failed messages
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "300s"
  }

  # Dead letter policy (equivalent to SQS DLQ)
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.summarization_jobs_dlq.id
    max_delivery_attempts = 5
  }

  # Enable exactly once delivery
  enable_exactly_once_delivery = true
}

# --- Dead Letter Topic for Failed Messages ---
resource "google_pubsub_topic" "summarization_jobs_dlq" {
  name = "summarization-jobs-dlq"

  depends_on = [google_project_service.pubsub]
}

# --- Dead Letter Subscription ---
resource "google_pubsub_subscription" "summarization_jobs_dlq_subscription" {
  name  = "summarization-jobs-dlq-subscription"
  topic = google_pubsub_topic.summarization_jobs_dlq.name

  # Longer retention for failed messages
  message_retention_duration = "604800s" # 7 days
  ack_deadline_seconds       = 600       # 10 minutes
}

# --- IAM bindings for Pub/Sub access ---
# Allow GKE workload identity service account to publish and subscribe
resource "google_pubsub_topic_iam_binding" "summarization_jobs_publisher" {
  topic = google_pubsub_topic.summarization_jobs.name
  role  = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.gke_workload_identity.email}"
  ]
}

resource "google_pubsub_subscription_iam_binding" "summarization_jobs_subscriber" {
  subscription = google_pubsub_subscription.summarization_jobs_subscription.name
  role         = "roles/pubsub.subscriber"

  members = [
    "serviceAccount:${google_service_account.gke_workload_identity.email}"
  ]
}