resource "google_compute_address" "jumpbox" {
  name         = "jbx-public-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "jumpbox" {
  name         = "${var.env_name}-jbx"
  machine_type = "${var.jumpbox_machine_type}"
  zone         = "${element(var.zones, 1)}"
  tags         = ["${var.env_name}-jumpbox-external"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-1804-bionic-v20190212a"
      size  = "50"
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = "${var.subnet}"

    access_config {
      nat_ip = "${google_compute_address.jumpbox.address}"
    }
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}
