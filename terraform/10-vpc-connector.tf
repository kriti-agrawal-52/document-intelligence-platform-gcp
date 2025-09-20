# VPC Access Connector for Cloud Run
# This allows Cloud Run services to access internal VPC resources like internal load balancers

# Enable VPC Access API
resource "google_project_service" "vpcaccess" {
  service = "vpcaccess.googleapis.com"
}

# Create VPC Access Connector
resource "google_vpc_access_connector" "connector" {
  name           = "${var.project_name}-vpc-connector"
  region         = var.gcp_region
  network        = google_compute_network.vpc.name
  ip_cidr_range  = "10.0.4.0/28"
  
  # Minimum instance configuration
  min_instances = 2
  max_instances = 3
  
  depends_on = [
    google_project_service.vpcaccess,
    google_compute_subnetwork.vpc_connector_subnet
  ]
}

# Output the connector name for Cloud Run deployment
output "vpc_connector_name" {
  description = "Name of the VPC Access Connector for Cloud Run"
  value       = google_vpc_access_connector.connector.name
}
