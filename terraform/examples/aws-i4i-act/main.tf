#
# AWS Standard ACT
#
# Run standard ACT test parameters against i4i instance types to validate ACT rating.
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
  vcpu_multiplier = 4
  test_runs = [
    {
      "act_rating": "35X"
      "instance_type": "i4i.2xlarge"
      "device_count": 1
      "partition_count": 2,
    },
    {
      "act_rating": "70X"
      "instance_type": "i4i.4xlarge"
      "device_count": 1
      "partition_count": 4,
    },
    {
      "act_rating": "70X"
      "instance_type": "i4i.8xlarge"
      "device_count": 2
      "partition_count": 4,
    },
    {
      "act_rating": "70X"
      "instance_type": "i4i.16xlarge"
      "device_count": 4
      "partition_count": 4,
    },
  ]
}

module "act_i4i" {
  source   = "../../modules/aws-aerospike-act"
  for_each = {for i, v in local.test_runs: "act_${v.instance_type}_${v.act_rating}_${v.device_count}x${v.partition_count}" => v}

  test_name             = each.key
  aws_ec2_key_pair      = var.aws_ec2_key_pair
  aws_instance_type     = each.value.instance_type
  aws_instance_count    = 1
  device_count          = each.value.device_count
  partition_count       = each.value.partition_count
  device_over_provision = 20
  act_config_template   = "${path.module}/config/act_storage.conf"

  act_config_vars       = {
    test_duration   = 3600 * 12
    #service_threads = each.value.service_threads
    read_tps        = tonumber(trimsuffix(each.value.act_rating, "X")) * 2000 * each.value.device_count
    write_tps       = tonumber(trimsuffix(each.value.act_rating, "X")) * 1000 * each.value.device_count
  }

  auto_start     = true
  auto_shutdown  = true
  skip_act_prep  = false

  s3_upload = true
  s3_bucket = var.aws_s3_bucket
  s3_path   = "aws-i4i-act/${formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())}"

  # microsecond histograms from 256us to 16,384us
  latency_args = "-h reads -h large-block-writes -h large-block-reads -s 8 -n 7 -e 1 -t 3600"
}

output "ssh_logins" {
  value = [for m in module.act_i4i : m.ssh_logins]
}
