resource "google_compute_firewall" "concourse-health_check" {
  name    = "cm-${var.env_name}-health-check"
  network = "${var.network}"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  target_tags = [
    "${var.env_name}-httplb",
  ]
}

resource "google_compute_firewall" "concourse-allow-http" {
  name          = "cm-${var.env_name}-allow-http"
  network       = "${var.network}"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  target_tags = ["cm-${var.env_name}-allow-http"]
}
