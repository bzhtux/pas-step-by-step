data "google_dns_managed_zone" "env_dns_zone" {
  name = "${var.env_name}"
}

resource "google_dns_record_set" "concourse" {
  name = "ci.${data.google_dns_managed_zone.env_dns_zone.dns_name}"
  type = "A"
  ttl  = 60

  managed_zone = "${data.google_dns_managed_zone.env_dns_zone.name}"

  rrdatas = ["${google_compute_address.concourse_global_ip.address}"]
}