resource "google_compute_firewall" "jumpbox" {
  name        = "jbx-firewall"
  network     = "${var.network}"
  target_tags = ["${var.env_name}-jumpbox-external"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
