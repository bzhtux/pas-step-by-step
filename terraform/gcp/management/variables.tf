variable "env_name" {
  type        = "string"
  default     = "dev"
  description = "Environment name"
}

variable "bosh_cidr" {
  type        = "string"
  default     = "10.0.20.0/24"
  description = "BOSH subnet CIDR"
}

variable "concourse_cidr" {
  type        = "string"
  default     = "10.0.30.0/24"
  description = "Concourse subnet CIDR"
}

variable "internetless" {
  default = true
}

variable "jbx_cidr" {
  type        = "string"
  default     = "10.0.10.0/24"
  description = "Jumpbox subnet CIDR"
}

variable "project" {
  type        = "string"
  default     = "cso-pcfs-emea-bzhtux"
  description = "GCP project to work on"
}

variable "region" {
  type        = "string"
  default     = "europe-west1"
  description = "GCP region ex us-central1"
}

variable "service_account_key" {
  type        = "string"
  default     = "/Users/yfoeillet/Documents/workdir/creds/gcp/bzhtux/cso-pcfs-emea-bzhtux-e8ed907d788d.json"
  description = "GCP service account key file"
}

variable "zones" {
  default = [
    "europe-west1-a",
    "europe-west1-b",
    "europe-west1-c",
  ]

  description = "GCP project to work on"
}
