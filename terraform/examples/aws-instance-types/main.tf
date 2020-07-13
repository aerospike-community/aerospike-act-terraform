#
# AWS Instance Types
#
# This example tests the same 20X workload on a single 900G local SSD instance 
# on 3 different instance types:
#
# - c5d.9xlarge
# - m5d.12xlarge
# - r5d.12xlarge
#
# Only a single device is tested on each instance and it is partitioned into 3
# ~300G logical devices.
#
# Test starts automatically, runs for 3 hours, upload results to S3, and then
# shuts down.
#

provider "aws" {
  region = "us-west-2"
}

locals {
  ec2_key_pair = "mcarrick"
  s3_bucket    = "mcarrick-act-results"
}

module "act_c5d" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = basename(abspath("${path.module}"))
  aws_ec2_key_pair      = local.ec2_key_pair
  aws_instance_type     = "c5d.9xlarge"
  aws_instance_count    = 1

  act_config_template   = "${path.module}/config/act_storage.conf"
  device_count          = 1
  partition_count       = 3

  skip_act_prep         = true
  auto_start            = true
  auto_shutdown         = true
  s3_upload             = true
  s3_bucket             = local.s3_bucket
}

module "act_m5d" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = basename(abspath("${path.module}"))
  aws_ec2_key_pair      = local.ec2_key_pair
  aws_instance_type     = "m5d.12xlarge"
  aws_instance_count    = 1

  act_config_template   = "${path.module}/config/act_storage.conf"
  device_count          = 1
  partition_count       = 3

  skip_act_prep         = true
  auto_start            = true
  auto_shutdown         = true
  s3_upload             = true
  s3_bucket             = local.s3_bucket
}

module "act_r5d" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = basename(abspath("${path.module}"))
  aws_ec2_key_pair      = local.ec2_key_pair
  aws_instance_type     = "r5d.12xlarge"
  aws_instance_count    = 1

  act_config_template   = "${path.module}/config/act_storage.conf"
  device_count          = 1
  partition_count       = 3

  skip_act_prep         = true
  auto_start            = true
  auto_shutdown         = true
  s3_upload             = true
  s3_bucket             = local.s3_bucket
}

output "device_names" {
  value = <<-EOF
  - c5d: ${module.act_c5d.device_names}
  - m5d: ${module.act_m5d.device_names}
  - r5d: ${module.act_r5d.device_names}
  EOF
}

output "ssh_logins" {
  value = <<-EOF
c5d Instances:
 - ${join("\n- ", [for ssh_login in module.act_c5d.ssh_logins : ssh_login])}

m5d Instances:
 - ${join("\n- ", [for ssh_login in module.act_m5d.ssh_logins : ssh_login])}

r5d Instances:
 - ${join("\n- ", [for ssh_login in module.act_m5d.ssh_logins : ssh_login])}
EOF
}
