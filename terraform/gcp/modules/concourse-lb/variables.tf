variable "env_name" {
  type        = "string"
  default     = "dev"
  description = "Environment name"
}

variable "project" {
  type        = "string"
  description = "GCP project to work on"
}

variable "region" {
  type        = "string"
  description = "GCP region ex us-central1"
}

variable "zones" {
  type = "list"

  default = [
    "europe-west1-b",
    "europe-west1-c",
    "europe-west1-d",
  ]

  description = "GCP project to work on"
}

variable "network" {
  type        = "string"
  description = "GCP global network"
}

variable "subnet" {
  type        = "string"
  description = "GCP subnet"
}
