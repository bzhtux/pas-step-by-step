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

resource "google_compute_router" "mgmt-nat-router" {
  name    = "mgmt-nat-router"
  region  = "${var.region}"
  network = "${google_compute_network.mgmt.self_link}"

  bgp {
    asn = 64514
  }
}

resource "google_compute_address" "mgmt-nat-address" {
  name   = "mgmt-nat-external-address-0"
  region = "${var.region}"
}

resource "google_compute_router_nat" "mgmt-advanced-nat" {
  name                               = "nat-mgmt"
  router                             = "${google_compute_router.mgmt-nat-router.name}"
  region                             = "${var.region}"
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = ["${google_compute_address.mgmt-nat-address.self_link}"]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "bosh-allow-ports" {
  name          = "bosh-allow"
  network       = "${google_compute_network.mgmt.name}"
  source_ranges = ["${var.jbx_cidr}"]
  target_tags   = ["bosh-internal"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["25555", "8443", "8844", "6868"]
  }
}

resource "google_compute_firewall" "cm-allow-icmp" {
  name          = "cm-allow-icmp"
  network       = "${google_compute_network.mgmt.name}"
  source_ranges = ["${var.bosh_cidr}", "${var.jbx_cidr}"]
  target_tags   = ["concourse"]

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "bosh-internal" {
  name        = "bosh-allow-internal"
  network     = "${google_compute_network.mgmt.name}"
  source_tags = ["bosh-internal"]
  target_tags = ["bosh-internal"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}



module "jumpbox" {
  source = "../modules/jumpbox"

  project  = "${var.project}"
  env_name = "${var.env_name}"
  zones    = "${var.zones}"
  subnet   = "${google_compute_subnetwork.jbx.name}"
  network  = "${google_compute_network.mgmt.name}"
}

module "concourse-lb" {
  source = "../modules/concourse-lb"

  project  = "${var.project}"
  env_name = "${var.env_name}"
  zones    = "${var.zones}"
  subnet   = "${google_compute_subnetwork.jbx.name}"
  network  = "${google_compute_network.mgmt.name}"
  region   = "${var.region}"
}
