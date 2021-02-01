#
# Terraform output for Aerospike ACT on GCP
#

output "test_name" {
  description = "Unique name for the test."
  value       = var.test_name
}

output "device_names" {
  description = "Comma-separated list of device names for this instance type."
  value       = join(",", local.logical_devices)
}

output "act_config" {
  description = "Rendered ACT configuration file."
  value       = data.template_file.act_config_template.rendered
}

output "cloud_config" {
  description = "Rendered cloud-init configuration file."
  value       = data.template_cloudinit_config.cloud_config.rendered
}

output "ssh_logins" {
  description = "Print [user]@[host] needed to SSH into each instance."
  value       = {
    for instance in google_compute_instance.act_instance:
      instance.name => "${var.ssh_user}@${instance.network_interface.0.access_config.0.nat_ip}"
  }
}
