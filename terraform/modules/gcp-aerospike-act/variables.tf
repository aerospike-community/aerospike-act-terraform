#
# Terraform variables for Aerospike ACT on AWS
#

variable "gcp_project" {
  description = "Name of Google Cloud project into which the instances will be launched."
  type        = string
}

variable "gcp_image_name" {
  description = "Exact name of a specific image. The 'aerospike-act' family will be specified if this is null."
  type        = string
  default     = null
}

variable "gcp_machine_type" {
  description = "Type of machine to test (eg. n2-standard-64)."
  type        = string
}

variable "gcp_cpu_platform" {
  default = "Intel Cascade Lake"
}

variable "gcp_instance_count" {
  description = "Number of instances to test. Default is 1."
  type        = number
  default     = 1
}

#variable "s3_upload" {
#  description = "Upload results to S3."
#  type        = bool
#  default     = false
#}

#variable "s3_bucket" {
#  description = "Name of S3 bucket to upload results to."
#  type        = string
#  default     = ""
#}
#
#variable "s3_path" {
#  description = "S3 path, without trailing slash, to upload results to. Eg. 'foo/bar'"
#  type        = string
#  default     = "act_results"
#}

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

variable "test_name" {
  description = "Unique name for the test used in output file names."
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

# pay attention to https://cloud.google.com/compute/docs/disks as the acceptable
# number of disks depends on the number of vCPUs
variable "device_count" {
  description = "Number of devices to test. Default is 0 which means maximum supported local NVMe SSD devices."
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

variable "iostat_interval" {
  description = "Interval in seconds for logging iostat output during the ACT run."
  type        = number
  default     = 60
}
