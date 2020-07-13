#
# AWS Quick Start Example
#
# Provisions a single EC2 instances and runs a a standard 1X ACT workload.
#

variable "aws_ec2_key_pair" {
  description = "Name for the AWS EC2 key pair to assiciate with the instances."
  type        = string
  default     = null
}

provider "aws" {
  region = "us-west-2"
}

module "act_quick_start" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = "quick_start"
  aws_ec2_key_pair      = var.aws_ec2_key_pair
  aws_instance_type     = "m5d.large"
  aws_instance_count    = 1
  act_config_template   = "${path.module}/config/act_storage.conf"

  auto_start            = true
  auto_shutdown         = false
}

output "device_names" {
  value = module.act_quick_start.device_names
}

output "ssh_logins" {
  value = module.act_quick_start.ssh_logins
}
