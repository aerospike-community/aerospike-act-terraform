#
# AWS Standard ACT
#
# Run standard ACT test parameters against common instance types at workload
# rates known to pass. 
#
# Tests are run on full-size instances to avoid "noisy neighbors".
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
  # common vars to use for every act test module
  aws_s3_path     = "aws-standard-act/${formatdate("YYYY-MM-DD", timestamp())}"
  instance_count  = 2
  c5d_act_rating  = 36   # 36x per drive, 144x total
  m5d_act_rating  = 30   # 30x per drive, 120x total
  r5d_act_rating  = 30   # 30x per drive, 120x total
  i3_act_rating   = 4    # 4x per drive, 32x total
  act_defaults    = {
    test_duration = 60 * 60 * 6 # = 6 hours
  }
  latency_args    = "-h reads -h device-reads -h large-block-writes -h large-block-reads -n 5 -e 1 -t 3600"
  skip_act_prep   = false 
}

module "act_c5d" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = "act_c5d"
  aws_ec2_key_pair      = var.aws_ec2_key_pair
  aws_instance_type     = "c5d.24xlarge"
  aws_instance_count    = local.instance_count

  device_count          = 4
  partition_count       = 3

  act_config_template   = "${path.module}/config/act_storage.conf"

  act_config_vars       = merge(local.act_defaults, {
    write_tps = 1000 * local.c5d_act_rating * 4
    read_tps  = 2000 * local.c5d_act_rating * 4
  })

  auto_start            = true
  auto_shutdown         = true
  skip_act_prep         = local.skip_act_prep

  s3_upload             = true
  s3_bucket             = var.aws_s3_bucket
  s3_path               = local.aws_s3_path

  latency_args          = local.latency_args
}

module "act_i3" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = "act_i3"
  aws_ec2_key_pair      = var.aws_ec2_key_pair
  aws_instance_type     = "i3.16xlarge"
  aws_instance_count    = local.instance_count

  device_count          = 8
  partition_count       = 4
  device_over_provision = 10

  act_config_template   = "${path.module}/config/act_storage.conf"

  act_config_vars       = merge(local.act_defaults, {
    write_tps = 1000 * local.i3_act_rating * 8
    read_tps  = 2000 * local.i3_act_rating * 8
  })

  auto_start            = true
  auto_shutdown         = true
  skip_act_prep         = local.skip_act_prep

  s3_upload             = true
  s3_bucket             = var.aws_s3_bucket
  s3_path               = local.aws_s3_path

  latency_args          = local.latency_args
}

module "act_m5d" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = "act_m5d"
  aws_ec2_key_pair      = var.aws_ec2_key_pair
  aws_instance_type     = "m5d.24xlarge"
  aws_instance_count    = local.instance_count

  device_count          = 4
  partition_count       = 3

  act_config_template   = "${path.module}/config/act_storage.conf"

  act_config_vars       = merge(local.act_defaults, {
    write_tps = 1000 * local.m5d_act_rating * 4
    read_tps  = 2000 * local.m5d_act_rating * 4
  })

  auto_start            = true
  auto_shutdown         = true
  skip_act_prep         = local.skip_act_prep

  s3_upload             = true
  s3_bucket             = var.aws_s3_bucket
  s3_path               = local.aws_s3_path

  latency_args          = local.latency_args
}

module "act_r5d" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = "act_r5d"
  aws_ec2_key_pair      = var.aws_ec2_key_pair
  aws_instance_type     = "r5d.24xlarge"
  aws_instance_count    = local.instance_count

  device_count          = 4
  partition_count       = 3

  act_config_template   = "${path.module}/config/act_storage.conf"

  act_config_vars       = merge(local.act_defaults, {
    write_tps = 1000 * local.r5d_act_rating * 4
    read_tps  = 2000 * local.r5d_act_rating * 4
  })

  auto_start            = true
  auto_shutdown         = true
  skip_act_prep         = local.skip_act_prep

  s3_upload             = true
  s3_bucket             = var.aws_s3_bucket
  s3_path               = local.aws_s3_path

  latency_args          = local.latency_args
}

output "ssh_logins" {
  value = <<-EOF

c5d Instances:
- ${join("\n- ", [for ssh_login in module.act_c5d.ssh_logins : ssh_login])}

i3 Instances:
- ${join("\n- ", [for ssh_login in module.act_i3.ssh_logins : ssh_login])}

m5d Instances:
- ${join("\n- ", [for ssh_login in module.act_m5d.ssh_logins : ssh_login])}

r5d Instances:
- ${join("\n- ", [for ssh_login in module.act_r5d.ssh_logins : ssh_login])}
EOF
}