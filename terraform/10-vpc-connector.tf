# VPC Connector for Cloud Run
# This enables Cloud Run services to access resources in the VPC (like internal load balancers)

# Enable VPC Access API
resource "google_project_service" "vpcaccess" {
  service = "vpcaccess.googleapis.com"
}

# Create VPC Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "doc-intel-vpc-connector"
  region        = var.gcp_region
  ip_cidr_range = "10.0.5.0/28"
  network       = google_compute_network.vpc.name
  
  depends_on = [
    google_project_service.vpcaccess
  ]
}

# Output the VPC connector name for use in Cloud Run deployment
output "vpc_connector_name" {
  description = "Name of the VPC connector for Cloud Run"
  value       = google_vpc_access_connector.connector.name
}
