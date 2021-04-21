#
# GCP Quick Start Example
#
# Provisions a single GCP instances and runs a a standard 1X ACT workload.
#

variable "ssh_user" {
  description = "Name of the user who will be logging into the instance via SSH."
  type        = string
  default     = null
}

variable "ssh_public_key_file" {
  description = "Full path to the public key of the user who will be logging into the instance via SSH."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "gcp_project" {
  description = "Name of Google Cloud project into which the instance will be launched."
  type        = string
}

provider "google" {
  project = var.gcp_project
  region  = "us-central1"
  zone    = "us-central1-a"
}

module "act_quick_start" {
  source = "../../modules/gcp-aerospike-act"

  ssh_user            = var.ssh_user
  ssh_public_key_file = var.ssh_public_key_file

  test_name = "quick_start"

  gcp_project        = var.gcp_project
  gcp_machine_type   = "n2-standard-2"
  gcp_instance_count = 1
  device_count       = 1

  act_config_template = "${path.module}/config/act_storage.conf"

  skip_act_prep = true
  auto_start    = true
  auto_shutdown = false
}

output "device_names" {
  value = module.act_quick_start.device_names
}

output "ssh_logins" {
  value = module.act_quick_start.ssh_logins
}
