#
# Terraform configuration for Aerospike ACT on AWS
#

locals {
  # map instance types to the local instance store device naming conventions
  instance_devices = {
    "c5d.large":     {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5d.xlarge":    {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5d.4xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5d.9xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5d.12xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "c5d.18xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "c5d.24xlarge":  {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "c5d.metal":     {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "c5ad.large":    {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5ad.xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5ad.4xlarge":  {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5ad.9xlarge":  {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5ad.12xlarge": {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "c5ad.18xlarge": {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "c5ad.24xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "c5dn.large":    {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5dn.xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5dn.4xlarge":  {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5dn.9xlarge":  {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "c5dn.12xlarge": {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "c5dn.18xlarge": {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "c5dn.24xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "i3.large":      {"count": 1, "prefix": "/dev/nvme", "offset": 0}
    "i3.xlarge":     {"count": 1, "prefix": "/dev/nvme", "offset": 0}
    "i3.2xlarge":    {"count": 1, "prefix": "/dev/nvme", "offset": 0}
    "i3.4xlarge":    {"count": 2, "prefix": "/dev/nvme", "offset": 0}
    "i3.8xlarge":    {"count": 4, "prefix": "/dev/nvme", "offset": 0}
    "i3.16xlarge":   {"count": 8, "prefix": "/dev/nvme", "offset": 0}
    "m5d.large":     {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "m5d.xlarge":    {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "m5d.2xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "m5d.4xlarge":   {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "m5d.8xlarge":   {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "m5d.12xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "m5d.16xlarge":  {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "m5d.24xlarge":  {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "m5d.metal":     {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "m5ad.large":    {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "m5ad.xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "m5ad.2xlarge":  {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "m5ad.4xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "m5ad.8xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "m5ad.12xlarge": {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "m5ad.16xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "m5ad.24xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "m5dn.large":    {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "m5dn.xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "m5dn.2xlarge":  {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "m5dn.4xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "m5dn.8xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "m5dn.12xlarge": {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "m5dn.16xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "m5dn.24xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "r5d.large":     {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "r5d.xlarge":    {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "r5d.2xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "r5d.4xlarge":   {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "r5d.8xlarge":   {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "r5d.12xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "r5d.16xlarge":  {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "r5d.24xlarge":  {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "r5ad.large":    {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "r5ad.xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "r5ad.2xlarge":  {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "r5ad.4xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "r5ad.8xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "r5ad.12xlarge": {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "r5ad.16xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "r5ad.24xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "r5dn.large":    {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "r5dn.xlarge":   {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "r5dn.2xlarge":  {"count": 1, "prefix": "/dev/nvme", "offset": 1}
    "r5dn.4xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "r5dn.8xlarge":  {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "r5dn.12xlarge": {"count": 2, "prefix": "/dev/nvme", "offset": 1}
    "r5dn.16xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
    "r5dn.24xlarge": {"count": 4, "prefix": "/dev/nvme", "offset": 1}
  }

  # physical devices such as /dev/nvme1n1, /dev/nvme2n1, etc.
  physical_devices = [
    for i in range(0, var.device_count > 0 ? var.device_count : local.instance_devices[var.aws_instance_type].count) : 
      "${local.instance_devices[var.aws_instance_type].prefix}${i+local.instance_devices[var.aws_instance_type].offset}n1"
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
  # https://github.com/terraform-providers/terraform-provider-aws/issues/265
  byte_length = 2

  keepers = {
    test_name = var.test_name
    s3_uri    = local.s3_uri
  }
}

data "aws_ami" "act_ami" {
    most_recent = true

    filter {
        name   = "name"
        values = [var.aws_ami_name]
    }

    owners = [var.aws_ami_owner]
}

data "template_file" "act_config_template" {
  template = file(var.act_config_template)

  vars = merge(var.act_config_vars, {
    "device_names": join(",", local.logical_devices)
  })
}


data "template_cloudinit_config" "cloud_config" {
  gzip          = false
  base64_encode = false

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

  # cloud-init script to create partitions; disk_setup cannot be used as it does
  # not support over-provisioning.
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
      act_cmd         = var.act_cmd
      auto_shutdown   = var.auto_shutdown ? 1 : 0
      auto_start      = var.auto_start
      config_file     = basename(var.act_config_template)
      config_content  = base64encode(data.template_file.act_config_template.rendered)
      devices         = join(" ", local.physical_devices)
      test_name       = var.test_name
      s3_uri          = var.s3_upload ? local.s3_uri : ""
      latency_args    = var.latency_args
      iostat_interval = 60
    })
  }
}

resource "aws_instance" "act_instance" {
  count                       = var.aws_instance_count
  instance_type               = var.aws_instance_type
  ami                         = data.aws_ami.act_ami.id
  vpc_security_group_ids      = [aws_security_group.act_instance_sg.id]
  subnet_id                   = var.aws_subnet_id
  key_name                    = var.aws_ec2_key_pair
  associate_public_ip_address = true
  user_data                   = data.template_cloudinit_config.cloud_config.rendered
  iam_instance_profile        = var.s3_upload ? aws_iam_instance_profile.instance_profile[0].name : null

  depends_on = [
    aws_iam_role.instance_role[0],
    aws_iam_instance_profile.instance_profile[0]
  ]

  tags = merge(local.all_tags, {Name = "ACT ${var.test_name} (${var.aws_instance_type} #${count.index + 1})"})
}

# --- Security groups ----------------------------------------------------------

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
      "Principal": { "Service": "ec2.amazonaws.com"},
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
      "Resource": ["arn:aws:s3:::${var.s3_bucket}"]
    },
    {
      "Effect": "Allow",
      "Action": "s3:*Object",
      "Resource": ["arn:aws:s3:::${var.s3_bucket}/${trim(var.s3_path, "/")}/*"]
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
