resource "google_compute_target_pool" "concourse_http_lb" {
  name = "cm-${var.env_name}-http-lb"

  session_affinity = "NONE"

  health_checks = [
    "${google_compute_http_health_check.concourse_hc.name}",
  ]
}

resource "google_compute_http_health_check" "concourse_hc" {
  name                = "cm-${var.env_name}-hc"
  port                = 8080
  request_path        = "/"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 3
  unhealthy_threshold = 2
}

resource "google_compute_forwarding_rule" "atc" {
  name        = "cm-${var.env_name}-control-plane-atc"
  target      = "${google_compute_target_pool.concourse_http_lb.self_link}"
  port_range  = "8080"
  ip_protocol = "TCP"
  ip_address  = "${google_compute_address.concourse_global_ip.address}"
}

resource "google_compute_address" "concourse_global_ip" {
  name = "cm-${var.env_name}-lb-ip"
}
