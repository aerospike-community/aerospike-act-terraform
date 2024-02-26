#
# AWS Standard ACT
#
# Run standard ACT test parameters against r7gd instance types to validate ACT rating.
#
variable "my_aws_ec2_key_pair" {
  description = "Name for the AWS EC2 key pair to associate with the instances."
  type        = string
  default     = ""
}
variable "my_aws_region" {
  description = "AWS region I want to launch in."
  type        = string
  default     = ""
}

variable "my_aws_ami_name" {
  description = "Use aerospike-act-arm64-6* for r7gd Graviton ARM64 instances"
  type        = string
  default     = "aerospike-act-6*"
}

variable "my_aws_ami_owner" {
  description = "My AWS Acct Id for AMI retrieval."
  type        = string
  default     = ""
}

variable "my_s3_upload" {
  description = "Upload ACT output to S3?"
  type        = bool
  default     = false
}

variable "my_s3_bucket" {
  description = "My AWS S3 bucket name."
  type        = string
  default     = ""
}

provider "aws" {
#  region = "us-east-1"
  region = var.my_aws_region
#  profile = "us"
}


locals {
  vcpu_multiplier = 4
  test_runs = [
    {
      "act_rating": "8X"
      "instance_type": "r7gd.medium"
      "device_count": 1
      "partition_count": 0
    },
    {
      "act_rating": "16X"
      "instance_type": "r7gd.large"
      "device_count": 1
      "partition_count": 0
    },
    {
      "act_rating": "32X"
      "instance_type": "r7gd.xlarge"
      "device_count": 1
      "partition_count": 0
    },
    {
      "act_rating": "65X"
      "instance_type": "r7gd.2xlarge"
      "device_count": 1
      "partition_count": 0
    },
    {
      "act_rating": "110X"
      "instance_type": "r7gd.4xlarge"
      "device_count": 1
      "partition_count": 0
    },
    {
      "act_rating": "95X"
      "instance_type": "r7gd.8xlarge"
      "device_count": 1 
      "partition_count": 2
    },
    {
      "act_rating": "125X"
      "instance_type": "r7gd.12xlarge"
      "device_count": 2 
      "partition_count": 2
    },
    {
      "act_rating": "105X"
      "instance_type": "r7gd.16xlarge"
      "device_count": 2 
      "partition_count": 2
    }
  ]
}

module "act_r7gd" {
  source   = "../../modules/aws-aerospike-act"
  for_each = {for i, v in local.test_runs: "act_${v.instance_type}_${v.act_rating}_${v.device_count}x${v.partition_count}" => v}

  test_name             = each.key
  aws_ec2_key_pair      = var.my_aws_ec2_key_pair
  aws_instance_type     = each.value.instance_type
  aws_instance_count    = 1
  device_count          = each.value.device_count
  partition_count       = each.value.partition_count
  device_over_provision = 20
  act_config_template   = "${path.module}/config/act_storage.conf"

  act_config_vars       = {
    test_duration   = 3600 * 24 # was: 3600 * 12 
    # final test should be 3600 * 24.
    #service_threads = each.value.service_threads
    read_tps        = tonumber(trimsuffix(each.value.act_rating, "X")) * 2000 * each.value.device_count
    write_tps       = tonumber(trimsuffix(each.value.act_rating, "X")) * 1000 * each.value.device_count
  }

  auto_start     = true
  auto_shutdown  = true
  skip_act_prep  = false

  aws_ami_name = var.my_aws_ami_name
  aws_ami_owner = var.my_aws_ami_owner
  s3_upload = var.my_s3_upload
  s3_bucket = var.my_s3_bucket
  s3_path   = "aws-r7gd-act/${formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())}"

  # microsecond histograms from 256us to 16,384us
  latency_args = "-h reads -h large-block-writes -h large-block-reads -s 8 -n 7 -e 1 -t 3600"
}

output "ssh_logins" {
  value = [for m in module.act_r7gd : m.ssh_logins]
}
