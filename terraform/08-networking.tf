# Static IP for Ingress Load Balancer
# This creates a global static IP that will be used by the GKE ingress

resource "google_compute_global_address" "ingress_ip" {
  name         = "doc-intel-ip"
  description  = "Static IP for Document Intelligence Platform Ingress"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}
