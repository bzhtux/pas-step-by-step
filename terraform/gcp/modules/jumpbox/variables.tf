variable "env_name" {
  type        = "string"
  default     = "dev"
  description = "Environment name"
}

variable "network" {
  type        = "string"
  default     = "default"
  description = "Jumpbox top network"
}

variable "project" {
  type        = "string"
  description = "GCP project to work on"
}

variable "zones" {
  type        = "list"
  description = "GCP project to work on"
}

variable "jumpbox_machine_type" {
  type        = "string"
  default     = "n1-standard-1"
  description = "Jumpbox instance type the GCP way"
}

variable "subnet" {
  type        = "string"
  default     = "default"
  description = "Jumpbox subnet"
}
