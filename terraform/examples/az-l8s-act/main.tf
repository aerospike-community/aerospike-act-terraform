#
# Azure Standard ACT
#
# Run standard ACT test parameters against Azure instance types to validate ACT rating.
#
variable "my_az_ec2_key_pair" {
  description = "Name for the Azure key pair to associate with the instances."
  type        = string
  default     = ""
}
variable "my_az_region" {
  description = "Azure region I want to launch in."
  type        = string
  default     = ""
}

# User specific, update in terraform.tfvars
variable "my_s3_aws_region" {
  description = "AWS region for s3 upload"
  type        = string
  default     = "us-east-1"
}

# Get from environment  TF_VAR_my_s3_aws_access_key="DeadFace" 
variable "my_s3_aws_access_key" {}

# Get from environment  TF_VAR_my_s3_aws_access_key="BabyFace" 
variable "my_s3_aws_secret_access_key" {}

variable "my_az_ami_owner" {
  description = "My Azure Acct Id for AMI retrieval."
  type        = string
  default     = ""
}

variable "my_s3_upload" {
  description = "Upload ACT output to S3?"
  type        = bool
  default     = false
}

variable "my_s3_bucket" {
  description = "My Azure S3 bucket name."
  type        = string
  default     = ""
}

provider "azurerm" {
  features {}
}

# Resource Group and resources that we need to create once.
# Per instance resources will be created in the modules/az-aerospike-act/main.tf

# Resource Group
resource "azurerm_resource_group" "aceACTrg" {
  name = "ace-act-resources"
  location = "East US"
  tags = {
   Owner = "az-act-test"
  }
}

# Networking Resources

resource "azurerm_virtual_network" "aceACTvnet" {
  name = "aceACTvnet1"
  location = azurerm_resource_group.aceACTrg.location
  resource_group_name = azurerm_resource_group.aceACTrg.name
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aceACTsubnet" {
  name = "aceACTVMsubnet"
  address_prefixes = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.aceACTvnet.name
  resource_group_name = azurerm_resource_group.aceACTrg.name
}
# Need to create instance specific nic in modules/az-aerospike-act/main.tf

locals {
  vcpu_multiplier = 4
  test_runs = [
    {
      "act_rating": "75X"
      "instance_type": "Standard_L8s_v3"
      "device_count": 1
      "partition_count": 2,
    },
    {
      "act_rating": "70X"
      "instance_type": "Standard_L16s_v3"
      "device_count": 2 
      "partition_count": 2,
    },
    {
      "act_rating": "75X"
      "instance_type": "Standard_L32s_v3"
      "device_count": 4
      "partition_count": 2,
    },
    {
      "act_rating": "75X"
      "instance_type": "Standard_L48s_v3"
      "device_count": 6
      "partition_count": 2,
    },
    {
      "act_rating": "70X"
      "instance_type": "Standard_L64s_v3"
      "device_count": 8
      "partition_count": 2,
    }
  ]
}

# ACT image
variable "my_az_image_name" {
  description = "ACT instance image"
  type        = string
  default = "aerospike-act-6.3-bb9b87b"
}

variable "my_az_image_rg_name" {
  description = "ACT instance image resource group name in Azure"
  type        = string
  default = "ace_act_images"
}

variable "my_az_public_key_file_name" {
 description = "Name for the Azure public key file for ssh."
 type    = string
 default = "~/.ssh/id_rsa.pub"
}


module "act_az" {
  source   = "../../modules/az-aerospike-act"
  for_each = {for i, v in local.test_runs: "ACT_${v.instance_type}_${v.act_rating}_${v.device_count}x${v.partition_count}" => v}

  az_image_rg_name         = var.my_az_image_rg_name
  az_image_name            = var.my_az_image_name
  az_rg_name               = azurerm_resource_group.aceACTrg.name
  az_rg_location           = azurerm_resource_group.aceACTrg.location
  az_subnet_id             = azurerm_subnet.aceACTsubnet.id
  test_name                = each.key
  az_public_key_file_name = var.my_az_public_key_file_name
  az_instance_type         = each.value.instance_type
  az_instance_count        = 1
  device_count             = each.value.device_count
  partition_count          = each.value.partition_count
  device_over_provision    = 20
  act_config_template      = "${path.module}/config/act_storage.conf"

  act_config_vars       = {
    test_duration   = 3600 * 24 
    # final test should be 3600 * 24.
    #service_threads = each.value.service_threads
    read_tps        = tonumber(trimsuffix(each.value.act_rating, "X")) * 2000 * each.value.device_count
    write_tps       = tonumber(trimsuffix(each.value.act_rating, "X")) * 1000 * each.value.device_count
  }

  auto_start     = true
  auto_shutdown  = true
  skip_act_prep  = false

  s3_aws_region = var.my_s3_aws_region
  s3_aws_access_key = var.my_s3_aws_access_key
  s3_aws_secret_access_key = var.my_s3_aws_secret_access_key

  s3_upload = var.my_s3_upload
  s3_bucket = var.my_s3_bucket
  s3_path   = "az-Lns_v3-act/${formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())}"

  # microsecond histograms from 256us to 16,384us
  latency_args = "-h reads -h large-block-writes -h large-block-reads -s 8 -n 7 -e 1 -t 3600"
}

output "ssh_logins" {
  value = [for m in module.act_az : m.ssh_logins]
}
