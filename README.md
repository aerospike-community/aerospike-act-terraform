Aerospike ACT Terraform
================================================================================

Automated [Aerospike Certification Tool (ACT)](https://github.com/aerospike/act)
testing on AWS and GCP.

[Packer](https://www.packer.io/) is used to create machine images with ACT
binaries installed and supporting systemd units to automate running tests.

[Terraform](https://www.terraform.io/) is used to provision the cloud resources
and apply specific test parameters.


1. Packer builds machine images
2. Terraform provisions instances based on configured test parameters
3. The `cloud-init` configurations: 
    1. Partition the volumes (optional)
    2. Run `act_prep` on the devices (optional)
    3. Copy test-specific parameters and configuration to the instance
4. The `systemd` units:
    1. Capture basic system information
    2. Execute the test with either `act_storage` or `act_index`
    3. Capture `iostat` output during the test run
    4. Upload results and logs to object storage (optional)
    5. Shutdown the instance (optional)


AWS Quick Start
--------------------------------------------------------------------------------

The quick start example will spin up a single `m5d.large` EC2 instance in the
`us-west-2` AWS region and automatically run a default 1X ACT test for 24 hours.

Before you begin you must
[setup AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
and create an [EC2 Key Pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair)
in the `us-west-2` AWS region.

---

Navigate to the `aws-quick-start` example module:

```
cd terraform/examples/aws-quick-start
```

View `terraform/examples/aws-quick-start/config/act_storage.conf`. This is the
ACT configuration file that will be copied onto each instance. It is documented
on the [ACT Github repo](https://github.com/aerospike/act).

View `terraform/examples/aws-quick-start/config/main.tf`. This is the main
Terraform configuration. The `act_simple` module is where the variables are
set that determine the instance type and device configuration for the test. To
see a description of all the available variables see
`terraform/modules/aws-aerospike-act/variables.tf`.

Initialize Terraform:

```
terraform init
```

Apply the Terraform plan, passing your EC2 key pair name as a variable so that
you will be able to SSH into the instance after it has been provisioned.

```
terraform apply -var aws_ec2_key_pair=<YOUR EC2 KEY PAIR NAME>
```

Type `yes` when prompted.

The output will include the SSH command you can use to login to the instance:

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

device_names = /dev/nvme1n1
ssh_logins = {
  "ACT simple (m5d.large #1)" = "ssh ec2-user@44.234.35.125"
}
```

SSH into the instance and verify the `cloud-init` script is running `act_prep`
on the local SSD device by tailing `/var/log/cloud-init-output.log`:

```
$ tail -f /var/log/cloud-init-output.log
```

This log will include the `act_prep` output which will take a while to run:

```
Cloud-init v. 19.3-3.amzn2 running 'modules:final' at Sun, 12 Jul 2020 12:23:37 +0000. Up 11.56 seconds.
Leaving devices unpartitioned: /dev/nvme1n1
Running act_prep on devices: /dev/nvme1n1
/dev/nvme1n1 size = 75000000000 bytes, 572204 large blocks
cleaning device /dev/nvme1n1
.....................................................................................................
salting device /dev/nvme1n1
.....................................................................................................
Created symlink from /etc/systemd/system/cloud-init.target.wants/aerospike-act.service to /etc/systemd/system/aerospike-act.service.
Cloud-init v. 19.3-3.amzn2 finished at Sun, 12 Jul 2020 12:59:42 +0000. Datasource DataSourceEc2.  Up 2176.80 seconds
```

When the `cloud-init` process is complete the `aerospike-act` service will start
automatically. Check the status with:

```
sudo systemctl status aerospike-act
```

The service runs a bunch of scripts before running the main act executable so
the output is a bit messy, but, the service should be "Loaded" and "Active":

```
● aerospike-act.service - Aerospike ACT
   Loaded: loaded (/etc/systemd/system/aerospike-act.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2020-07-12 12:59:42 UTC; 6min ago
  Process: 2961 ExecStartPre=/bin/bash -c { set -x && cat /etc/system-release && lscpu && lsblk && ifconfig; } >> /var/log/act/$ACT_TEST/sysinfo.txt 2>&1 (code=exited, status=0/SUCCESS)
  Process: 2952 ExecStartPre=/bin/bash -c { echo "AWS Instance ID: $(wget -T 2 -q -O - http://169.254.169.254/latest/meta-data/instance-id)" && echo "AWS Instance Type: $(wget -T 2 -q -O - http://169.254.169.254/latest/meta-data/instance-type)" && echo "AWS AMI ID: $(wget -T 2 -q -O - http://169.254.169.254/latest/meta-data/ami-id)"; } >> /var/log/act/$ACT_TEST/sysinfo.txt 2>&1 (code=exited, status=0/SUCCESS)
  Process: 2947 ExecStartPre=/bin/bash -c echo "Creating /var/log/act/$ACT_TEST" && /bin/mkdir -p /var/log/act/$ACT_TEST && touch /var/log/act/$ACT_TEST/sysinfo.txt (code=exited, status=0/SUCCESS)
 Main PID: 2968 (bash)
   CGroup: /system.slice/aerospike-act.service
           ├─2968 /bin/bash -c echo "Running $ACT_CMD" && /usr/sbin/$ACT_CMD $ACT_CONFIG > /var/log/act/$ACT_TEST/$ACT_CMD.stdout.txt 2> /var/log/act/$ACT_TEST/...
           └─2970 /usr/sbin/act_storage /opt/act/act_storage.conf
```

If for any reason the service failed, you can view the logs with
`journalctl -u aerospike-act`. For example, to tail the last 10 lines:

```
journalctl -u aerospike-act -n 10
```

As the test is going to run for 24 hours, it should show "Running act_storage"
as the last log entry:

```
-- Logs begin at Sun 2020-07-12 11:40:00 UTC, end at Sun 2020-07-12 13:07:18 UTC. --
Jul 12 12:59:42 ip-172-31-45-102.us-west-2.compute.internal systemd[1]: Starting Aerospike ACT...
Jul 12 12:59:42 ip-172-31-45-102.us-west-2.compute.internal bash[2947]: Creating /var/log/act/quick_start
Jul 12 12:59:42 ip-172-31-45-102.us-west-2.compute.internal systemd[1]: Started Aerospike ACT.
Jul 12 12:59:42 ip-172-31-45-102.us-west-2.compute.internal bash[2968]: Running act_storage
```

Tail the output of ACT:

```
tail -f /var/log/act/quick_start/act_storage.stdout.txt
```

Tail the output of `iostat` which is also setup to run periodically and log it's
output during the test:

```
tail -f /var/log/act/quick_start/iostat.stdout.txt
```

View a latency report of the test output thus far:

```
act_latency -l /var/log/act/quick_start/act_storage.stdout.txt -h reads -h large-block-writes -n 3 -e 3 -t 60
```

When you are done testing, tear down the environment:

```
terraform destroy
```

Building Images
--------------------------------------------------------------------------------

Navigate into the `packer/` directory:

```
cd packer
```

### Build AMIs for AWS

Build the `act-aws.json` template:

```
packer build act-aws.json
```

To build in a different region:

```
packer build -var region=us-east-1 act-aws.json
```

### Build Sepcific ACT versions

To build a specific version of ACT specify the git ref and ACT version strings:

**ACT 6.1**

```
packer build -var act_version=6.1 -var act_git_ref=ed2584b <build_template>
```

**ACT 6.0**

```
packer build -var act_version=6.0 -var act_git_ref=5637286 <build_template>
```

**ACT 5.3**

```
packer build -var act_version=5.3 -var act_git_ref=7df031f <build_template>
```

**ACT 5.2**

```
packer build -var act_version=5.2 -var act_git_ref=0ea97dc <build_template>
```

**ACT 5.1**

```
packer build -var act_version=5.1 -var act_git_ref=db9961f <build_template>
```

**ACT 5.0**

```
packer build -var act_version=5.0 -var act_git_ref=2cca411 <build_template>
```


Manual Testing
--------------------------------------------------------------------------------

The test will be run automatically when `auto_start=true`. However, the test can
be run manually by setting `auto_start=false` and either invoking the `systemd`
units directly or running the ACT binaries directly.

### Using ACT binaries

The ACT source code is cloned to `/home/ec2-user/act` and the binaries are
installed to `/usr/sbin`. Run with:

* `sudo act_prep ...`
* `sudo act_storage ...`
* `sudo act_index ...`
* `sudo act_latency ...`

The ACT config file can be found in `/opt/act/`


### Using systemd

Use `systemctl` to `start|stop|restart|status` the `aerospike-act` service.
View logs with `journalctl -u aerospike-act`.

The `aerospike-act` service uses environment variables that were installed by
`cloud-init` to `/opt/act/environment`. They can be manually altered before
(re)starting the service.

The service is setup to store it's output at `/var/log/act/<test-name>`.


Troubleshooting
--------------------------------------------------------------------------------

### Troubleshooting cloud-init

The `systemd` unit files are setup to run _after_ `cloud-init` completes. If the
devices are being prepped with `act_prep` at boot, which is the default, then
the `cloud-init` process can take a while (up to an hour).

To see if `cloud-init` is still running:

```
$ sudo cloud-init status
status: running
```

To view output from the `cloud-init` process, including partitioning and running
`act_prep` on the devices, see the `cloud-init-output.log`:

```
$ tail -f /var/log/cloud-init-output.log
```
