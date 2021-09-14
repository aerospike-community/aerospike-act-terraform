#
# Terraform configuration for Aerospike ACT on GCP
#

locals {
  # map instance types to the local instance store device naming conventions
  instance_devices = {
    "n2-standard-2" : { "count" : 8, "prefix" : "/dev/nvme", "offset" : 0 }
    "n2-standard-4" : { "count" : 8, "prefix" : "/dev/nvme", "offset" : 0 }
    "n2-standard-8" : { "count" : 8, "prefix" : "/dev/nvme", "offset" : 0 }
    "n2-standard-16" : { "count" : 8, "prefix" : "/dev/nvme", "offset" : 0 }
    "n2-standard-32" : { "count" : 8, "prefix" : "/dev/nvme", "offset" : 0 }
    "n2-standard-48" : { "count" : 8, "prefix" : "/dev/nvme", "offset" : 0 }
    "n2-standard-64" : { "count" : 8, "prefix" : "/dev/nvme", "offset" : 0 }
    "n2-standard-80" : { "count" : 8, "prefix" : "/dev/nvme", "offset" : 0 }
  }

  # physical devices such as /dev/nvme1n1, /dev/nvme2n1, etc.
  physical_devices = [
    for i in range(0, var.device_count > 0 ? var.device_count : local.instance_devices[var.gcp_machine_type].count) :
    "${local.instance_devices[var.gcp_machine_type].prefix}${i + local.instance_devices[var.gcp_machine_type].offset}n1"
  ]

  # logical devices (partitions) such as /dev/nvme1n1p1, /dev/nvme1n1p1
  logical_devices = flatten([
    for device in local.physical_devices :
    var.partition_count > 0 ? [for j in range(1, var.partition_count + 1) : "${device}p${j}"] : [device]
  ])
}


data "google_compute_image" "act_image" {
  family  = var.gcp_image_name == null ? "aerospike-act" : null
  name    = var.gcp_image_name != null ? var.gcp_image_name : null
  project = var.gcp_project
}

data "template_file" "act_config_template" {
  template = file(var.act_config_template)

  vars = merge(var.act_config_vars, {
    "device_names" : join(",", local.logical_devices)
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

    content = templatefile("${path.module}/cloud-init/create-partitions.sh", {
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

    content = templatefile("${path.module}/cloud-init/run-act-prep.sh", {
      skip_act_prep = var.skip_act_prep ? 1 : 0
      devices       = join(",", local.logical_devices)
    })
  }

  # cloud-init config to write the ACT configuration file to /opt/act
  part {
    content_type = "text/cloud-config"
    filename     = "aerospike-act.yml"

    content = templatefile("${path.module}/cloud-init/act-config.yml", {
      act_cmd         = var.act_cmd
      auto_shutdown   = var.auto_shutdown ? 1 : 0
      auto_start      = var.auto_start
      config_file     = basename(var.act_config_template)
      config_content  = base64encode(data.template_file.act_config_template.rendered)
      devices         = join(" ", local.physical_devices)
      test_name       = var.test_name
      latency_args    = var.latency_args
      iostat_interval = 60
    })
  }
}

resource "google_compute_instance" "act_instance" {
  count            = var.gcp_instance_count
  name             = "act${count.index + 1}-${var.test_name}-${var.gcp_machine_type}"
  machine_type     = var.gcp_machine_type
  min_cpu_platform = var.gcp_cpu_platform

  boot_disk {
    initialize_params {
      image = data.google_compute_image.act_image.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys  = "${var.ssh_user}:${file(var.ssh_public_key_file)}"
    user-data = data.template_cloudinit_config.cloud_config.rendered
  }

  dynamic "scratch_disk" {
    for_each = local.physical_devices
    content {
      interface = "NVME"
    }
  }
}
