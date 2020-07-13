#
# Terraform output for Aerospike ACT on AWS
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
    for instance in aws_instance.act_instance:
      instance.tags.Name => "ssh ec2-user@${instance.public_ip}"
  }
}
