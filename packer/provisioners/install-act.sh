#!/usr/bin/env bash

sudo yum install gcc git make sysstat wget -y

echo "Checking out ACT $ACT_GIT_REF"
git clone https://github.com/aerospike/act.git
cd act
git -c advice.detachedHead=false checkout $ACT_GIT_REF

echo "Building ACT"
make

echo "Installing ACT binaries"
sudo cp target/bin/act_storage /usr/sbin/act_storage
sudo cp target/bin/act_prep /usr/sbin/act_prep
sudo cp target/bin/act_index /usr/sbin/act_index
sudo cp analysis/act_latency.py /usr/sbin/act_latency.py
sudo ln -s /usr/sbin/act_latency.py /usr/sbin/act_latency

echo "Creating log directory"
sudo mkdir /var/log/act

echo "Copying systemd configuration"
sudo cp /tmp/aerospike-act*.service /etc/systemd/system/
sudo systemctl enable aerospike-act-iostat.service
