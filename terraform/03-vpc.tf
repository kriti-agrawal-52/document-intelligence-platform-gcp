# /terraform/03-vpc.tf

# FILE PURPOSE:
# This file is responsible for creating the networking infrastructure for our GCP resources.
# It defines the VPC (Virtual Private Cloud) which acts as a virtual network where all our resources will live.
# It also creates subnets (both public and private), firewall rules, and routing.
# This provides the foundation for our GKE cluster and other GCP services to communicate securely.

# Enable required APIs
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

resource "google_project_service" "container" {
  service = "container.googleapis.com"
}

resource "google_project_service" "servicenetworking" {
  service = "servicenetworking.googleapis.com"
}

# --- VPC Network ---
# Create the main VPC network for our infrastructure
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  description             = "VPC network for Document Intelligence Platform"

  depends_on = [google_project_service.compute]
}

# --- Private Subnet ---
# Private subnet for GKE nodes and internal services
resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.project_name}-private-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc.name

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }

  # Enable private Google access for nodes without external IPs
  private_ip_google_access = true
}

# --- Public Subnet ---
# Public subnet for load balancers and other internet-facing resources
resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.project_name}-public-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc.name
}

# --- Cloud Router ---
# Router for NAT gateway to allow private instances to access the internet
resource "google_compute_router" "router" {
  name    = "${var.project_name}-router"
  region  = var.gcp_region
  network = google_compute_network.vpc.id
}

# --- NAT Gateway ---
# NAT gateway to allow outbound internet access from private subnet
resource "google_compute_router_nat" "nat" {
  name   = "${var.project_name}-nat"
  router = google_compute_router.router.name
  region = var.gcp_region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# --- Firewall Rules ---
# Allow internal communication within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
}

# Allow SSH access
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-allowed"]
}

# Allow HTTP and HTTPS traffic
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.project_name}-allow-http-https"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8000", "8001", "8002"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

# --- Private Service Connection ---
# Reserve IP range for private services (Cloud SQL, etc.)
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Create private connection for managed services
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [google_project_service.servicenetworking]
}