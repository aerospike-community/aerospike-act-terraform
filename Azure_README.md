```Java

```

Running ACT on Azure
================================================================================

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
    
Running the automated [Aerospike Certification Tool (ACT)](https://github.com/aerospike/act)
tests on desired Azure instances follows the same steps as we did on AWS, however, creating the ACT image on Azure using `packer` is not automated via scripts. We will create it _once_ via the [Azure Portal](https://portal.azure.com). This image will be available in our Azure subscription and will be used by the terraform scripts to launch the instance types we intend to test.    
    
Azure Subscription and Account Setup
------------------------------------------------------------------------------

You will be working in your own organization's account. We will show the steps here as followed with the Aerospike Organization account. 

The account administrator will have to add you to the Aerospike Azure account and assign a subscription id with role as "Owner". This role will allow you to create resource groups and resources in Azure.

You will have to set up your 2FA via an authenticator, such as the Microsoft Authenticator App on your cell phone.

This is allow you to log into your [Azure portal](https://portal.azure.com)    

<img src="./AzureACTFigs/Fig1_AzurePortalLogin.png"
     alt="AzurePortalLogin"
     style="center; margin-right: 10px;"
     width="600"
     height="480"/>
 
Select your aeropsike.com account (free trial accounts don't have quotas to launch instances that we will need to test for Aerospike.)

Check if you have a subscription allocated.  Click on "Subscriptions" icon on the dashboard. 
<img src="./AzureACTFigs/Fig2_AzSubscription.png"
     alt="AzurePortalLogin"
     style="center; margin-right: 10px;"
     width="300"
     height="240"/>

You should see your subscription and role as Owner. 

<img src="./AzureACTFigs/Fig3_AzSubscription.png"
     alt="AzurePortalLogin"
     style="center; margin-right: 10px;"
     width="640"
     height="200"/>
     

Azure Specific ACT Test Procedure Outline
------------------------------------------------------------------------------

1 - On https://portal.azure.com, manually create a resource group.  for e.g.  `ace_act_images` The instance image with ACT repo and executables that we will create once, using packer, will be saved in this resource group for launching various ACT test instances.

2 - Run packer to create the ACT image.  (Uses Centos8.5 for updated cloud-init support.)

3 - Run terraform scripts to do the ACT test on selected instance type.

When running terraform scripts to run ACT tests, you will need to install `azure-cli` on your local machine.  The cli will authenticate your access to Azure via the Azure portal (that we just set up above). We will explore this further in the Terraform scripts execution section.

Detailed Steps
------------------------------------------------------------------------------ 

**Creating Resource Group for ACT Image**

(Note:  Any user may be able to use the image added in ace_act_images resource group, already present, and this step can be omitted by the next user in "ACS Development 2" group subscription.)

On Azure Dashboard … click on the "Hamburger" menu icon →


<img src="./AzureACTFigs/Fig4_PortalHamburgerIcon.png"
     alt="AzureResources"
     style="center; margin-right: 10px;"
     width="150"
     height="120"/>


and create a Resource Group  in East US region. 


<img src="./AzureACTFigs/Fig5_PortalResourceGroups.png"
     alt="AzureResources"
     style="center; margin-right: 10px;"
     width="400"
     height="400"/>
     
     
The resource group is added to ACS Development 2 subscription as shown below:


<img src="./AzureACTFigs/Fig6_ResourceGroupsListed.png"
     alt="AzureResources"
     style="center; margin-right: 10px;"
     width="400"
     height="400"/>


### packer: Installation & Image Creation

In your `aerospike-act-terraform` repo, navigate to: aerospike-act-terraform/packer

_Edit:_ `act-az.json` and add your `client_secret`, `client_id` and `subscription_id` from the Azure portal.  There may be a better way to alternately add these to the `.bashrc` file and use env variable names, but in the current script, they are hard coded. (Do not check-them back into the repo. Values shown here are no longer valid).

#### Getting Client ID and Client Secret

This has to be done by registering the packer app in the Azure portal. 

In Azure portal,  "Hamburger" icon menu: Active Directory (Now renamed as: **_Microsoft Entra ID_**) → select App Registration  → + New Registraton → Type any name …  **ace-act-packer**  … and register.


<img src="./AzureACTFigs/Fig7_AzureActiveDirectory.png"
     alt="AppCredentials"
     style="center; margin-right: 10px;"
     width="400"
     height="400"/>
     
     
     
     
<img src="./AzureACTFigs/Fig8_AppRegistrations.png"
     alt="AppRegistration"
     style="center; margin-right: 10px;"
     width="400"
     height="600"/>
     
  
(Name in screenshot … app was renamed to: ace-act-packer)
  
     
<img src="./AzureACTFigs/Fig9_RegisterApplication.png"
     alt="AppRegistration"
     style="center; margin-right: 10px;"
     width="400"
     height="600"/>
     
     
Click on **Register** → gives _ClientID, ObjectID_ etc:
     
     
<img src="./AzureACTFigs/Fig10_AppClientID.png"
     alt="AppCredentials"
     style="center; margin-right: 10px;"
     width="650"
     height="230"/>

_client_id:_  dc536883-258e-4294-bfc2-03061d268974  

In Certificates and Secrets, add a new Client Secret - _"ace-act-packer-client-secret"_ :


<img src="./AzureACTFigs/Fig11_AppClientSecret.png"
     alt="AppCredentials"
     style="center; margin-right: 10px;"
     width="640"
     height="400"/>
     
_secret_id:_ 9f8ac340-c011-4d55-9e95-14902a918f59
_Value:_ **Js88Q~hrEKBuvWcuglfqFkNqYiXTSsa2G_p6Ya1O** 

Save it safely, this is the password, will not be visible later and will be needed in the `act-az.json` script. 


<img src="./AzureACTFigs/Fig12_AppClientSecretSave.png"
     alt="AppCredentials"
     style="center; margin-right: 10px;"
     width="800"
     height="120"/>
     

(**Note:** This _Value_ is for illustration only, not a valid _Value_ currently.)

Finally, _subscription_id:_ dc7b8f77-f812-449e-9724-f6a4109b20d4  

Available in Subscriptions menu, main dashboard. 

<img src="./AzureACTFigs/Fig13_SubscriptionID.png"
     alt="AppCredentials"
     style="center; margin-right: 10px;"
     width="640"
     height="400"/>
     
     
Update `act-az.json`. 

In builders, for type `azure-arm`, add your _client_id, client_secret_ and _subscription_id_:
```
{
  "type": "azure-arm",
  "client_id" : "dc536883-258e-4294-bfc2-03061d268974",
  "client_secret" : "Js88Q~hrEKBuvWcuglfqFkNqYiXTSsa2G_p6Ya1O",
  "subscription_id" : "dc7b8f77-f812-449e-9724-f6a4109b20d4",
  "image_publisher" : "OpenLogic",
  "image_offer" : "CentOS",
  "image_sku" : "8_5-gen2",
  "os_type" : "Linux",
  "managed_image_name" : "aerospike-act-{{user `act_version` | clean_resource_name}}-{{ user `act_git_ref` }}",
  "managed_image_resource_group_name" : "ace_act_images",
  "location" : "East US",
  "vm_size" : "Standard_B1s"
}
```

#### Set Application Role

Give `ace-act-packer` App - `Owner` role.
Go to Subscriptions → ACS Development 2 → Access Control (IAM) 


<img src="./AzureACTFigs/Fig14_AppAccessControl.png"
     alt="AppRole"
     style="center; margin-right: 10px;"
     width="400"
     height="640"/>


#### Add Role Assingment

Select the app as the "member" to assign role to.

<img src="./AzureACTFigs/Fig15_AppRoleAssignment.png"
     alt="AppRole"
     style="center; margin-right: 10px;"
     width="640"
     height="400"/>
     
     
In Role Tab, select Privileged administrator roles and select owner.



<img src="./AzureACTFigs/Fig16_AppRoleAssignment.png"
     alt="AppRole"
     style="center; margin-right: 10px;"
     width="500"
     height="400"/>
     
<img src="./AzureACTFigs/Fig17_AppRoleAssignment.png"
     alt="AppRole"
     style="center; margin-right: 10px;"
     width="640"
     height="400"/>
     
#### Build the ACT Image

We are in: `/aerospike-act-terraform/packer`

**Note:**  `act-az.json` has AWS AMI builder also (to be deleted later). We must run only the `azure-arm` builder as follows:

```
packer build -only=azure-arm act-az.json

```

This will launch a temporary instance of type "Standard_B1s", create the Azure Image using CentOS 8.5 - gen 2  base image and then installs ACT ver 6.3. The image is saved in the `ace_act_images` resource group. Script destroys its temporary instance when done.

Script updates the OS - so a lot of patches to apply, takes a while to build. In future, we will launch instances using this image.



<img src="./AzureACTFigs/Fig18_ACTImageBuild.png"
     alt="AppBuild"
     style="center; margin-right: 10px;"
     width="800"
     height="120"/>
     

Check → Hamburger menu → Resource Groups → ace_act_images … 

<img src="./AzureACTFigs/Fig19_ACTImage.png"
     alt="AppBuild"
     style="center; margin-right: 10px;"
     width="640"
     height="400"/>   
     
This is a one time build. Other users in this group can start off this image.


### Using Azure CLI for Terraform Session Authentication

We use Terraform for the initial deployment of a cluster which relies on the authenticated session of the azure cli.  In turn the azure cli relies on the oauth authentication of the user performing the deployment. This authentication flow is much more secure than using service principals with shared certificates or passwords as it restricts access to specific users and relies on time limited oauth tokens. 

To use this method, on the working machine, we must install azure-cli.  

For MacOS:

https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos 

```
brew update && brew install azure-cli
```

### Terraform: Running ACT Test 

First, log into your `ACS Development2 azure` account from the shell command line.   

```
az login 

```

This will open a browser window to login to azure portal. Pick the correct account to log in. If successful, you can close the browser window and the command line will show something like this:



<img src="./AzureACTFigs/Fig21_az_cli_login.png"
     alt="az-cli_Login"
     style="center; margin-right: 10px;"
     width="800"
     height="400"/>  
     

Modify main.tf per the test you are doing .. then:

```
terraform plan
terraform apply 
. . . 
Enter a value: yes
. . .
```

When done, before re-running ACT on same or another instance type:

```
terraform destroy
. . . 
Enter a value: yes
. . .
```

#### Analyzing the Results

On the ACT test instance, in `/var/log/act/act_Standard_L16s_v3_30X_2x2`
 
``` 
act_latency.py -l act_storage.stdout.txt -h reads -h large-block-writes -h large-block-reads -s 8 -n 7 -e 1 -t 300

```

### Uploading Results to Amazon S3

#### AWS Single Sign-on (SSO)

Basics:  https://aws.amazon.com/what-is/sso/  

<img src="./AzureACTFigs/Fig22_S3_Setup.png"
     alt="S3_Access"
     style="center; margin-right: 10px;"
     width="640"
     height="400"/>  


#### Environmental Variables in Terraform

Added installation of `awscli` via cloud-init on the Azure linux instance.
It needs aws access and secret to write to S3. We can pass those as environmental variables.

Any variable exported in `.bashrc` as `TF_VAR_varname="Value"` and used in terraform as:
variable `"varname"  {}`   .. will pick its value from the environment variable.

User must add in .bashrc their credentials for S3 bucket:

```
export TF_VAR_s3_aws_access_key="xxxx"
export TF_VAR_s3_aws_secret_access_key="zzzzz"
```

And in `main.tf`:   
variable "s3_aws_access_key" { }

```
unset TF_VAR_s3_aws_access_key   

```
will delete/clear the environment variable.








```Java

```
