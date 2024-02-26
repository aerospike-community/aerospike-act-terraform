#
# AWS Quick Start Example
#
# Provisions a single EC2 instances and runs a a standard 1X ACT workload.
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

module "act_quick_start" {
  source               = "../../modules/aws-aerospike-act"

  test_name             = "quick_start"
  aws_ec2_key_pair      = var.my_aws_ec2_key_pair
  aws_instance_type     = "m5d.large"
  aws_instance_count    = 1
  act_config_template   = "${path.module}/config/act_storage.conf"
  aws_ami_owner         = var.my_aws_ami_owner
  s3_upload             = var.my_s3_upload
  s3_bucket             = var.my_s3_bucket
  auto_start            = true
  auto_shutdown         = false
}

output "device_names" {
  value = module.act_quick_start.device_names
}

output "ssh_logins" {
  value = module.act_quick_start.ssh_logins
}
