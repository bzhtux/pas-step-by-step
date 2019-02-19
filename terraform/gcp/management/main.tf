resource "google_compute_network" "mgmt" {
  name                    = "${var.env_name}-mgmt-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "jbx" {
  name                     = "${var.env_name}-jbx-subnet"
  ip_cidr_range            = "${var.jbx_cidr}"
  network                  = "${google_compute_network.mgmt.self_link}"
  region                   = "${var.region}"
  private_ip_google_access = "${var.internetless}"
}

resource "google_compute_subnetwork" "bosh" {
  name                     = "${var.env_name}-bosh-subnet"
  ip_cidr_range            = "${var.bosh_cidr}"
  network                  = "${google_compute_network.mgmt.self_link}"
  region                   = "${var.region}"
  private_ip_google_access = "${var.internetless}"
}

resource "google_compute_subnetwork" "concourse" {
  name                     = "${var.env_name}-concourse-subnet"
  ip_cidr_range            = "${var.concourse_cidr}"
  network                  = "${google_compute_network.mgmt.self_link}"
  region                   = "${var.region}"
  private_ip_google_access = "${var.internetless}"
}

resource "google_compute_firewall" "bosh-allow-ports" {
  name      = "bosh-allow"
  network   = "${google_compute_network.mgmt.name}"
  source_ranges = ["${var.jbx_cidr}"]
  target_tags = ["bosh-internal"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["25555", "8443", "8844", "6868"]
}   
}


module "jumpbox" {
  source = "../modules/jumpbox"

  project  = "${var.project}"
  env_name = "${var.env_name}"
  zones    = "${var.zones}"
  subnet   = "${google_compute_subnetwork.jbx.name}"
  network   = "${google_compute_network.mgmt.name}"
}
