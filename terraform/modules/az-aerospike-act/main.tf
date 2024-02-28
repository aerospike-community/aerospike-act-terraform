#
# Terraform configuration for Aerospike ACT on Azure
#

locals {
  # map instance types to the local instance store device naming conventions
  instance_devices = {
    "Standard_L8s_v3":     {"count": 1, "prefix": "/dev/nvme", "offset": 0}
    "Standard_L16s_v3":    {"count": 2, "prefix": "/dev/nvme", "offset": 0}
    "Standard_L32s_v3":    {"count": 4, "prefix": "/dev/nvme", "offset": 0}
    "Standard_L48s_v3":    {"count": 6, "prefix": "/dev/nvme", "offset": 0}
    "Standard_L64s_v3":    {"count": 8, "prefix": "/dev/nvme", "offset": 0}
    "Standard_L80s_v3":    {"count": 10, "prefix": "/dev/nvme", "offset": 0}
  }

  # physical devices such as /dev/nvme1n1, /dev/nvme2n1, etc.
  physical_devices = [
    for i in range(0, var.device_count > 0 ? var.device_count : local.instance_devices[var.az_instance_type].count) : 
      "${local.instance_devices[var.az_instance_type].prefix}${i+local.instance_devices[var.az_instance_type].offset}n1"
  ]

  # logical devices (partitions) such as /dev/nvme1n1p1, /dev/nvme1n1p1
  logical_devices = flatten([
    for device in local.physical_devices :
      var.partition_count > 0 ? [for j in range(1, var.partition_count+1) : "${device}p${j}"] : [device]
  ])

  s3_uri = var.s3_path != "" ? "s3://${var.s3_bucket}/${trim(var.s3_path, "/")}" : "s3://${var.s3_bucket}"

  all_tags = {
    Name    = "ACT ${var.test_name}"
    ActTest = var.test_name
  }
}

resource "random_id" "sg_random" {
  # Add random digits to resources that are created before they are destroyed
  # but need to have a unique identifier. Security groups and IAM resources are
  # particularly vulnerable due to the "eventual consistency" of those services.
  # https://github.com/terraform-providers/terraform-provider-az/issues/265
  byte_length = 2

  keepers = {
    test_name = var.test_name
    s3_uri    = local.s3_uri
  }
}

/*
# AWS image to use, pre-built by packer.
data "az_ami" "act_ami" {
    most_recent = true

    filter {
        name   = "name"
        values = [var.az_ami_name]
    }

    owners = [var.az_ami_owner]
}
*/

# Update act config file for one or multiple devices under test
data "template_file" "act_config_template" {
  template = file(var.act_config_template)

  vars = merge(var.act_config_vars, {
    "device_names": join(",", local.logical_devices)
  })
}


data "template_cloudinit_config" "cloud_config" {
  #gzip          = false
  #base64_encode = false
  gzip          = true
  base64_encode = true

  # cloud-init script to create partitions; disk_setup cannot be used as it does
  # not support over-provisioning.
  part {
    content_type = "text/x-shellscript"
    filename     = "partitions.sh"
    content      = templatefile("${path.module}/cloud-init/create-partitions.sh", {
      devices         = join(" ", formatlist("\"%s\"", local.physical_devices))
      partition_count = var.partition_count
      over_provision  = var.device_over_provision
    })
  }

  # cloud-init script to install awscli to ship result to s3
  part {
    content_type = "text/x-shellscript"
    filename     = "install-awscli.sh"
    content      = templatefile("${path.module}/cloud-init/install-awscli.sh", {
      aws_region = var.s3_aws_region
      aws_access_key_id = var.s3_aws_access_key
      aws_secret_access_key = var.s3_aws_secret_access_key
    })
  }


  # cloud-init script to run act-prep
  part {
    content_type = "text/x-shellscript"
    filename     = "run-act-prep.sh"

    content      = templatefile("${path.module}/cloud-init/run-act-prep.sh", {
      skip_act_prep  = var.skip_act_prep ? 1 : 0
      devices        = join(",", local.logical_devices)
    })
  }

  # cloud-init config to write the ACT configuration file to /opt/act
  part {
    content_type = "text/cloud-config"
    filename     = "aerospike-act.yml"

    content      = templatefile("${path.module}/cloud-init/act-config.yml", {
      act_cmd           = var.act_cmd
      auto_shutdown     = var.auto_shutdown ? 1 : 0
      auto_start        = var.auto_start
      config_file       = basename(var.act_config_template)
      config_content    = base64encode(data.template_file.act_config_template.rendered)
      devices           = join(" ", local.physical_devices)
      test_name         = var.test_name
      s3_uri            = var.s3_upload ? local.s3_uri : ""
      latency_args      = var.latency_args
      iostat_interval   = 60
      azure_ami_id      = "${data.azurerm_image.search.id}"
      act_instance_type = var.az_instance_type
    })
  }
}


# Launch test instance VM
resource "azurerm_public_ip" "aceACTPublicIP" {
#resource "azurerm_public_ip" {var.test_name} {
  #name = "aceACTnicPublicIP"
  name = "${var.test_name}"
  location = var.az_rg_location
  resource_group_name = var.az_rg_name
  allocation_method = "Static"
  tags = {
    environment = "Test"
  }
}
data "azurerm_public_ip" "aceACTPublicIpData" {
#data "azurerm_public_ip" {var.test_name} {
  name                = azurerm_public_ip.aceACTPublicIP.name
  #name                = azurerm_public_ip.{var.test_name}.name
  resource_group_name = var.az_rg_name
}
# Output format, per instance - To be updated
output "public_ip_address" {
  value = data.azurerm_public_ip.aceACTPublicIpData.ip_address
  #value = data.azurerm_public_ip.{var.test_name}.ip_address
}

# Network Interface Card, per instance
resource "azurerm_network_interface" "aceACTnic" {
#resource "azurerm_network_interface" {var.test_name} {
  #name = "aceACTVMnic"
  name = "${var.test_name}"
  location = var.az_rg_location
  resource_group_name = var.az_rg_name
  ip_configuration {
    name = "internal"
    subnet_id = var.az_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.aceACTPublicIP.id
    #public_ip_address_id = azurerm_public_ip.{var.test_name}.id
  }
}

# Locate the existing custom / golden image  (TBD: make it a variable?)
# name = "aerospike-act-6.3-bb9b87b"
# resource_group_name = "ace_act_images"

data "azurerm_image" "search" {
  name = var.az_image_name
  resource_group_name = var.az_image_rg_name
}

# Azure instance types e.g.  size="Standard_L8s_v3"

resource "azurerm_linux_virtual_machine" "aceACTLinuxVM" {
  computer_name                = "aceACTlinuxVM"
  name = "${var.test_name}" 
  resource_group_name = var.az_rg_name
  location            = var.az_rg_location
  size                = var.az_instance_type
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.aceACTnic.id,
    #azurerm_network_interface.{var.test_name}.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    #public_key = file("~/.ssh/id_rsa.pub")
    public_key = file(var.az_public_key_file_name)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    #name                 = "aceACT-os-storage-disk"
    name                 = "${var.test_name}"
  }
  source_image_id = "${data.azurerm_image.search.id}"

# Run cloudinit
  custom_data              = data.template_cloudinit_config.cloud_config.rendered
}
#3 resource "az_instance" "act_instance" {
#3   count                       = var.az_instance_count
#3   instance_type               = var.az_instance_type
#3   ami                         = data.az_ami.act_ami.id
#3   vpc_security_group_ids      = [az_security_group.act_instance_sg.id]
#3   subnet_id                   = var.az_subnet_id
#3   key_name                    = var.az_ec2_key_pair
#3   associate_public_ip_address = true
#3   user_data                   = data.template_cloudinit_config.cloud_config.rendered
#3   iam_instance_profile        = var.s3_upload ? az_iam_instance_profile.instance_profile[0].name : null
#3 
#3   depends_on = [
#3     az_iam_role.instance_role[0],
#3     az_iam_instance_profile.instance_profile[0]
#3   ]
#3 
#3   tags = merge(local.all_tags, {Name = "ACT ${var.test_name} (${var.az_instance_type} #${count.index + 1})"})
#3 }

# --- Security groups ----------------------------------------------------------
/*
resource "aws_security_group" "act_instance_sg" {
  name        = "aerospike_act_${random_id.sg_random.hex}"
  description = "Aerospike ACT: ${var.test_name}"
  vpc_id      = var.aws_vpc_id

  # Allow SSH in
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allow_cidrs
  }

  # Allow SSH, HTTP, and HTTPS out
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.all_tags

  lifecycle { 
    create_before_destroy = true 
  }
}

# --- IAM role if uploading results to S3 --------------------------------------

resource "aws_iam_role" "instance_role" {
  count = var.s3_upload ? 1 : 0

  name               = "AerospikeActAssumeRole_${var.test_name}_${random_id.sg_random.hex}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaz.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags               = local.all_tags
}

resource "aws_iam_instance_profile" "instance_profile" {
  count = var.s3_upload ? 1 : 0

  name  = "AerospikeActInstanceProfile_${var.test_name}_${random_id.sg_random.hex}"
  role  = aws_iam_role.instance_role[0].name
}

resource "aws_iam_policy" "s3_upload_policy" {
  count  = var.s3_upload ? 1 : 0

  name   = "AerospikeActS3UploadPolicy_${var.test_name}_${random_id.sg_random.hex}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:az:s3:::${var.s3_bucket}"]
    },
    {
      "Effect": "Allow",
      "Action": "s3:*Object",
      "Resource": ["arn:az:s3:::${var.s3_bucket}/${trim(var.s3_path, "/")}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_upload_policy_attachment" {
  count  = var.s3_upload ? 1 : 0

  role       = aws_iam_role.instance_role[0].name
  policy_arn = aws_iam_policy.s3_upload_policy[0].arn
}
*/
