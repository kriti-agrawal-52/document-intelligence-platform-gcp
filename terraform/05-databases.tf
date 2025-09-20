# /terraform/05-databases.tf

# FILE PURPOSE:
# This file creates the database infrastructure for our application using Google Cloud services.
# It provisions Cloud SQL (MySQL), Firestore (document database), and Redis (caching).
# This replaces AWS RDS, DocumentDB, and ElastiCache with their GCP equivalents.

# Enable required APIs
resource "google_project_service" "sql_admin" {
  service = "sqladmin.googleapis.com"
}

# Firestore API not needed - using Kubernetes MongoDB instead
# resource "google_project_service" "firestore" {
#   service = "firestore.googleapis.com"
# }

resource "google_project_service" "redis" {
  service = "redis.googleapis.com"
  
  # Prevent deletion of the service
  disable_on_destroy = false
  
  # Wait for API to be fully enabled
  timeouts {
    create = "10m"
  }
}

# --- Cloud SQL MySQL Instance ---
# This replaces AWS RDS MySQL and provides the MySQL database for user authentication
resource "google_sql_database_instance" "mysql_instance" {
  name             = "${var.project_name}-mysql-${random_string.db_suffix.result}"
  database_version = "MYSQL_8_0"
  region           = var.gcp_region
  
  settings {
    tier = "db-f1-micro"  # Smallest instance for development (equivalent to AWS db.t3.micro)
    
    # Networking - equivalent to AWS VPC security groups
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
      require_ssl     = false
    }
    
    # Backup configuration - equivalent to AWS RDS automated backups
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.gcp_region
      transaction_log_retention_days = 7
    }
    
    # Maintenance window - equivalent to AWS RDS maintenance window
    maintenance_window {
      day          = 7  # Sunday
      hour         = 4  # 4 AM
      update_track = "stable"
    }
  }

  deletion_protection = false  # Set to true for production

  depends_on = [
    google_project_service.sql_admin,
    google_service_networking_connection.private_vpc_connection
  ]
}

# Create the auth database - equivalent to AWS RDS database creation
resource "google_sql_database" "auth_db" {
  name     = "auth_db"
  instance = google_sql_database_instance.mysql_instance.name
}

# Create MySQL user - equivalent to AWS RDS master user
resource "google_sql_user" "mysql_user" {
  name     = "app_user"
  instance = google_sql_database_instance.mysql_instance.name
  password = var.mysql_password
}

# --- MongoDB Database ---
# Note: We deploy MongoDB as a Kubernetes pod instead of using Firestore
# This maintains compatibility with existing application code that expects MongoDB
# For production, consider migrating to Firestore or using MongoDB Atlas
# MongoDB deployment is handled in kubernetes/09-mongodb-deployment.yaml

# --- Redis Instance ---
# This replaces AWS ElastiCache and provides caching and JWT blacklist functionality
resource "google_redis_instance" "cache" {
  name           = "${var.project_name}-redis"
  memory_size_gb = 1
  region         = var.gcp_region
  
  # Use basic tier for development (no high availability) - equivalent to AWS single-node
  tier = "BASIC"
  
  # Redis version
  redis_version = "REDIS_7_0"
  
  # Network - equivalent to AWS VPC security groups
  authorized_network = google_compute_network.vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  
  depends_on = [
    google_project_service.redis,
    google_service_networking_connection.private_vpc_connection
  ]
}

# --- Random string for unique naming ---
resource "random_string" "db_suffix" {
  length  = 4
  special = false
  upper   = false
}