#
# GCP multiple test scenarios
#
# Provisions multiple gcp instances testing permutations of config
#

locals {
  ssh_user            = "your_user"
  ssh_public_key_file = "~/.ssh/id_rsa.pub"
  gcp_project         = "your_project"
  gcp_region          = "us-west1"
  gcp_zone            = "us-west1-c"

  instance_type  = "n2-standard-4"
  instance_count = 2

  device_count = 1

  test_duration_sec = 21600 # 6 hours

  scenarios = {
    "50x-1024k" : { "write_reqs_per_sec" : "42000", "read_reqs_per_sec" : "84000", "large_block_op_kbytes" : "1024" }
    "54x-512k" : { "write_reqs_per_sec" : "54000", "read_reqs_per_sec" : "108000", "large_block_op_kbytes" : "512" }
    "58x-128k" : { "write_reqs_per_sec" : "58000", "read_reqs_per_sec" : "116000", "large_block_op_kbytes" : "128" }
  }
}

provider "google" {
  project = local.gcp_project
  region  = local.gcp_region
  zone    = local.gcp_zone
}

module "gcp_act" {
  for_each = local.scenarios
  source   = "../../modules/gcp-aerospike-act"

  ssh_user            = local.ssh_user
  ssh_public_key_file = local.ssh_public_key_file

  test_name = each.key

  gcp_project        = local.gcp_project
  gcp_machine_type   = local.instance_type
  gcp_instance_count = local.instance_count
  device_count       = local.device_count

  act_config_vars = merge(each.value, { "test_duration_sec" : local.test_duration_sec })

  act_config_template = "${path.module}/config/act_storage.conf"

  skip_act_prep = true
  auto_start    = true
  auto_shutdown = false
}

output "ssh_logins" {
  value = [for t in module.gcp_act : t.ssh_logins]
}
