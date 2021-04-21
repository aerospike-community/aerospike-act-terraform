#!/usr/bin/env bash

echo "Updating system..."
sudo yum update -y

echo "Installing cloud-init..."
sudo yum install -y cloud-init
sudo systemctl enable cloud-init

echo "Rebooting..."
sudo reboot