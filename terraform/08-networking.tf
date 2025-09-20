# Static IP for Ingress Load Balancer
# This creates a global static IP that will be used by the GKE ingress

resource "google_compute_global_address" "ingress_ip" {
  name         = "doc-intel-ip"
  description  = "Static IP for Document Intelligence Platform Ingress"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

# Firewall rule to allow GCP health checks to reach NodePort services
# This is required for GCP Load Balancer to perform health checks on backend services

resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-gcp-health-checks"
  network = google_compute_network.vpc.name

  description = "Allow GCP health checks to reach NodePort services for ingress"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]  # Full NodePort range for flexibility
  }

  source_ranges = [
    "35.191.0.0/16",    # GCP health check range 1
    "130.211.0.0/22",   # GCP health check range 2
  ]

  target_tags = ["gke-node"]
}
