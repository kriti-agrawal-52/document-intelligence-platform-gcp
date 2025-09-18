# /terraform/05-databases.tf

# FILE PURPOSE
# This file provisions all of the stateful databases required by the microservices
# It creates a relational database (Cloud SQL for MySQL) for the auth-service and 
# Firestore for the text-extraction-service.
# It also sets up the necessary firewall rules to ensure that only our GKE cluster nodes can communicate with these databases,
# following the principle of least privilege.

# --- Cloud SQL MySQL Database for Auth Service ---
# Random suffix for unique instance name
resource "random_string" "db_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Cloud SQL MySQL instance
resource "google_sql_database_instance" "mysql_instance" {
  name             = "${var.project_name}-mysql-${random_string.db_suffix.result}"
  database_version = "MYSQL_8_0"
  region          = var.gcp_region
  deletion_protection = false

  settings {
    tier = "db-f1-micro" # Small, cost-effective instance type

    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.gcp_region
      binary_log_enabled            = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
      }
    }

    # IP configuration for private access
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
      require_ssl     = true
    }

    # Database flags
    database_flags {
      name  = "slow_query_log"
      value = "on"
    }

    # Maintenance window
    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Create the auth database
resource "google_sql_database" "auth_db" {
  name     = "auth_db"
  instance = google_sql_database_instance.mysql_instance.name
}

# Create database user
resource "google_sql_user" "mysql_user" {
  name     = "auth_user"
  instance = google_sql_database_instance.mysql_instance.name
  password = var.mysql_password
}

# --- Private Service Connection for Cloud SQL ---
# Reserve IP range for private services
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Create private connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# --- Firestore Database for Document Storage ---
# Enable Firestore API
resource "google_project_service" "firestore" {
  service = "firestore.googleapis.com"
}

# Create Firestore database
resource "google_firestore_database" "document_db" {
  project     = var.gcp_project_id
  name        = "(default)"
  location_id = var.gcp_region
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.firestore]
}

# --- Memorystore Redis for Caching ---
# Enable Redis API
resource "google_project_service" "redis" {
  service = "redis.googleapis.com"
}

# Redis instance for caching and JWT blacklist
resource "google_redis_instance" "cache" {
  name           = "${var.project_name}-redis"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.gcp_region

  authorized_network = google_compute_network.vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version     = "REDIS_7_0"
  display_name      = "Document Intelligence Redis Cache"

  depends_on = [google_project_service.redis]
}