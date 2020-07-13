#
# Terraform variables for Aerospike ACT on AWS
#

variable "aws_vpc_id" {
  description = "ID of the VPC in which to deploy instances. Default is the AWS account default VPC."
  type        = string
  default     = null
}

variable "aws_subnet_id" {
  description = "ID of the subnet in which to deploy instances. Default is the AWS account default public subnet."
  type        = string
  default     = null
}

variable "aws_ami_owner" {
  description = "Account ID of the owner of the ACT AMI. Default is Micah Carrick <mcarrick@aerospike.com>."
  type        = string
  default     = "696609415687"
}

variable "aws_ami_name" {
  description = "Name for the filter used to query the most recent AMI. Default is 'aerospike-act-*'."
  type        = string
  default     = "aerospike-act-6*"
}

variable "aws_ec2_key_pair" {
  description = "Name for the AWS EC2 key pair to assiciate with the instance."
  type        = string
}

variable "aws_instance_type" {
  description = "Type of EC2 instance to test."
  type        = string
}

variable "aws_instance_count" {
  description = "Number of EC2 instance to test. Default is 1."
  type        = number
  default     = 1
}

variable "test_name" {
  description = "Unique name for the test. This is used in AWS tags and output file names."
  type        = string
}

variable "auto_start" {
  description = "Execute the test automatically at boot."
  type        = bool
  default     = false
}

variable "auto_shutdown" {
  description = "Shutdown the instance automatically after the test complets or fail."
  type        = bool
  default     = false
}

variable "act_cmd" {
  description = "Command to run act. Default is act_storage."
  type        = string
  default     = "act_storage"
}

variable "act_config_template" {
  description = "Template string for ACT configuration file."
  type        = string
}

variable "act_config_vars" {
  description = "Custom variables to pass into the ACT configuration file template."
  type        = map
  default     = {}
}

variable "device_count" {
  description = "Number of devices to test. Default is 0 which means test all instance store NVMe SSD devices."
  type        = number
  default     = 0
}


variable "device_over_provision" {
  description = "Amount of space to leave \"over-provisioned\" on the disk. Eg. use '10' for 10%."
  type        = number
  default     = 0
}

variable "partition_count" {
  description = "Number of partitions per device. Default is 0 which means no logical partitions will be created."
  type        = number
  default     = 0
}

variable "skip_act_prep" {
  description = "Skip running act_prep on the devices at first boot."
  type        = bool
  default     = false
}

variable "latency_args" {
  description = "Arguments passed to act_latency to generate a latency report."
  type        = string
  default     = "-h reads -h device-reads -h large-block-writes -h large-block-reads -n 3 -e 3 -t 3600"
}

variable "s3_upload" {
  description = "Upload results to S3."
  type        = bool
  default     = false
}

variable "s3_bucket" {
  description = "Name of S3 bucket to upload results to."
  type        = string
  default     = ""
}

variable "s3_path" {
  description = "S3 path, without trailing slash, to upload results to. Eg. 'foo/bar'"
  type        = string
  default     = "act_results"
}

variable "iostat_interval" {
  description = "Interval in seconds for logging iostat output during the ACT run."
  type        = number
  default     = 60
}

variable "ssh_allow_cidrs" {
  description = "List of CIDR blocks that are allowed to SSH into the instances. Default is all (0.0.0.0/0)."
  type        = list
  default     = ["0.0.0.0/0"]
}


