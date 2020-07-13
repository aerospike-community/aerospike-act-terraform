#
# AWS Standard ACT
#
# Run standard ACT test parameters against common instance types at workload
# rates known to pass a 12 hour test run. 
#
# Tests are run on full-size instances to avoid "noisy neighbors".
#
# Tests are run on 3 instances to account for some variability between instances,
# however, real-world testing should validate a larger sample size.
#

variable "aws_ec2_key_pair" {
  description = "Name for the AWS EC2 key pair to assiciate with the instances."
  type        = string
  default     = null
}

variable "aws_s3_bucket" {
  description = "Name of S3 bucket in which to store results."
  type        = string
}

provider "aws" {
  region = "us-west-2"
}

locals {
  aws_s3_path        = "aws-standard-act/${formatdate("YYYY-MM-DD", timestamp())}"
  c5d_act_rating = 36
  m5d_act_rating = 10
  r5d_act_rating = 30
  act_defaults   = {}
}

# 36x per drive, 72x total
module "act_c5d" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = "act_c5d"
  aws_ec2_key_pair      = var.aws_ec2_key_pair
  aws_instance_type     = "c5d.24xlarge"
  aws_instance_count    = 3

  device_count          = 2
  partition_count       = 3

  act_config_template   = "${path.module}/config/act_storage.conf"

  act_config_vars       = merge(local.act_defaults, {
    write_tps = 1000 * local.c5d_act_rating * 2
    read_tps  = 2000 * local.c5d_act_rating * 2
  })

  auto_start            = true
  auto_shutdown         = true

  s3_upload             = true
  s3_bucket             = var.aws_s3_bucket
  s3_path               = local.aws_s3_path
}

# 10x per drive, 40x total
module "act_m5d" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = "act_m5d"
  aws_ec2_key_pair      = var.aws_ec2_key_pair
  aws_instance_type     = "m5d.24xlarge"
  aws_instance_count    = 3

  device_count          = 4
  partition_count       = 3

  act_config_template   = "${path.module}/config/act_storage.conf"

  act_config_vars       = merge(local.act_defaults, {
    write_tps = 1000 * local.m5d_act_rating * 4
    read_tps  = 2000 * local.m5d_act_rating * 4
  })

  auto_start            = true
  auto_shutdown         = true

  s3_upload             = true
  s3_bucket             = var.aws_s3_bucket
  s3_path               = local.aws_s3_path
}

# 30x per drive, 120x total
module "act_r5d" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = "act_r5d"
  aws_ec2_key_pair      = var.aws_ec2_key_pair
  aws_instance_type     = "r5d.24xlarge"
  aws_instance_count    = 3

  device_count          = 4
  partition_count       = 3

  act_config_template   = "${path.module}/config/act_storage.conf"

  act_config_vars       = merge(local.act_defaults, {
    write_tps = 1000 * local.m5d_act_rating * 4
    read_tps  = 2000 * local.m5d_act_rating * 4
  })

  auto_start            = true
  auto_shutdown         = true

  s3_upload             = true
  s3_bucket             = var.aws_s3_bucket
  s3_path               = local.aws_s3_path
}

output "ssh_logins" {
  value = <<-EOF
c5d Instances:
- ${join("\n- ", [for ssh_login in module.act_c5d.ssh_logins : ssh_login])}

m5d Instances:
- ${join("\n- ", [for ssh_login in module.act_m5d.ssh_logins : ssh_login])}

r5d Instances:
- ${join("\n- ", [for ssh_login in module.act_r5d.ssh_logins : ssh_login])}
EOF
}