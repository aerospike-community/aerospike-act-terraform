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
  #value       = {
    #for instance in azurerm_linux_virtual_machine.aceACTLinuxVM:
    #  instance.name => "ssh adminuser@${instance.public_ip_address}"
    value = "${azurerm_linux_virtual_machine.aceACTLinuxVM.name} => ssh adminuser@${azurerm_linux_virtual_machine.aceACTLinuxVM.public_ip_address} -i ~/.ssh/id_rsa "
  #}
}
