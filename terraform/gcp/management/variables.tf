variable "env_name" {
  type        = "string"
  description = "Environment name"
}

variable "bosh_cidr" {
  type        = "string"
  description = "BOSH subnet CIDR"
}

variable "concourse_cidr" {
  type        = "string"
  description = "Concourse subnet CIDR"
}

variable "internetless" {
  default = true
}

variable "jbx_cidr" {
  type        = "string"
  description = "Jumpbox subnet CIDR"
}

variable "project" {
  type        = "string"
  description = "GCP project to work on"
}

variable "region" {
  type        = "string"
  description = "GCP region ex us-central1"
}

variable "service_account_key" {
  type        = "string"
  description = "GCP service account key file"
}

variable "zones" {
  default = []
  description = "GCP project to work on"
}
