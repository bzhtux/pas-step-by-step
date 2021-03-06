```bash
 ____   _    ____        _               _                 _             
|  _ \ / \  / ___|   ___| |_ ___ _ __   | |__  _   _   ___| |_ ___ _ __  
| |_) / _ \ \___ \  / __| __/ _ \ '_ \  | '_ \| | | | / __| __/ _ \ '_ \ 
|  __/ ___ \ ___) | \__ \ ||  __/ |_) | | |_) | |_| | \__ \ ||  __/ |_) |
|_| /_/   \_\____/  |___/\__\___| .__/  |_.__/ \__, | |___/\__\___| .__/ 
                                |_|            |___/              |_|    
```

PAS (Pivotal Application Service) step by step is a training program to help you learning how to deploy Pivotal Cloud Foundry.

# Overview

This step by step training is based on Google Cloud Platform (GCP). You will follow the steps below to build a complete infrastructure for PAS.

1. Deploy management infrastructure
2. Create a jumpbox
3. From jumpbox create a management BOSH director
4. From jumpbox and using management BOSH director deploy concourse
5. Create pipelines:
	1. deploy PAS infrastructure using terraform
	2. deploy opsman
	3. using opsman deploy PAS

	
# Network and subnets

Main network is named `${var.env_name}-mgmt-network` with 3 subnets:

 - `${var.env_name}-jbx-subnet` : dedicated to jumpbox
 - `${var.env_name}-bosh-subnet` : dedicated to BOSH (the management one)
 - `${var.env_name}-concourse-subnet` : dedicated to concourse

where `${var.env_name}` comes from terraform variables.

## Subnets CIDRs:

* Jumpbox CIDR: 10.0.10.0/24
* BOSH CIDR: 10.0.20.0/24
* Concourse CIDR: 10.0.30.0/24

| Network | Subnets | Instances |
|:--------|:--------|:----------|
| ${var.env-name}-mgmt-network | ${var.env_name}-jbx-subnet | jumpbox |
| ${var.env-name}-mgmt-network | ${var.env_name}-bosh-subnet | bosh director |
| ${var.env-name}-mgmt-network | ${var.env_name}-concourse-subnet | concourse web |
| ${var.env-name}-mgmt-network | ${var.env_name}-concourse-subnet | concourse db |
| ${var.env-name}-mgmt-network | ${var.env_name}-concourse-subnet | concourse worker |

## Architecture

![Management infrastructure schema](assets/images/infra-mgmt.png)
	
	
# Step1: deploy management infrastructure

## What's new ?

Everything ! The first thing to do is building the management infrastructure that will host:

 - a jumpbox
 - a bosh director instance
 - a concourse deployment (3 instances)

To deploy infrastructure you will use a custom terraform recipe from the [github repository](https://github.com/bzhtux/pas-step-by-step/)


## Get

From within your local workdir, run the following commands to get codebase and step1:

```bash
git clone github.com:bzhtux/pas-step-by-step.git
cd pas-step-by-step
git checkout step1
```


## Run

From within the `pas-step-by-step` directory, run the following commands to deploy infrastructure:

```bash
cd terraform/gcp/management/
terraform init 	# to init terraform with providers and modules
terraform plan -out plan
terraform apply plan
```

From GCP console you can see a new network with 3 subnets.

# Step2: create a jumpbox

## What's new ?

Now the management infrastructure is deployed, let's create a jumpbox with terraform. In this step you'll need a domain name (example: domain.com) with a zone delegation for `${var.env_name}` configured with dns servers provided by Google DNS.

Exmaple:

```bash
dig +short NS ${var.env_name}.domain.com
ns-cloud-c1.googledomains.com.
ns-cloud-c2.googledomains.com.
ns-cloud-c3.googledomains.com.
ns-cloud-c4.googledomains.com.
```

A new dns record (`A`) with a `TTL=60` will be set for `jbx.${var.env_name}.domain.com` with public ip address generated by terraform.

## Get

From within the `pas-step-by-step` directory run the following command to get step2 source code:

```bash
git checkout step2
```

## Run

From within the `pas-step-by-step` directory, run the following commands to deploy infrastructure:

```bash
cd terraform/gcp/management/
terraform plan -out plan
terraform apply plan
```

The private ip address associated to the jumpbox is dynamically allocated using DHCP.

Connect to the jumpbox using gcloud:

```bash
gcloud compute --project "<GCP PROJECT NAME>" ssh --zone "<GCP ZONE>" "<YOUR LOCAL USER>@${var.env_name}-jbx"
```

You will be provided a new ssh keypair dedicated to GCP in your `~/.ssh/` directory.

Now edit your SSH configuration file to add your jumpbox `~/.ssh/config`:

```bash
Host *
    StrictHostKeyChecking no
    UpdateHostKeys no
    PubkeyAcceptedKeyTypes +ssh-dss
    ServerAliveInterval 60
    ServerAliveCountMax 2
    ForwardAgent yes
    SendEnv LANG LC_* GIT_*
    User <your username>
    
[...]
Host jbx.${var.env_name}.domain.com
    IdentityFile ~/.ssh/google_compute_engine
    StrictHostKeyChecking no
[...]
```

Save the configuration file and try to establish a new SSH connection:

```bash
ssh jbx.${var.env_name}.domain.com
```

If everything is correct you should be connected to your jumpbox.

# Step3: create a management BOSH director

## What's new ?
At this point, management infrastructure is deployed and jumpbox is created, so let's create the bosh director using [github/cloudfoundry/bosh-deployment](https://github.com/cloudfoundry/bosh-deployment.git). You'll need to add a new firewall rule (terraform provides it for you) to allow jumpbox (bosh client) to interact with the bosh director.

In order to access bosh director from jumpbox, following ports should be opened:

- TCP/25555
- TCP/8443
- TCP/8844
- TCP/6868

from source range `10.0.10.0/24`.

## Get

From within the `pas-step-by-step` directory run the following command to get step3 source code:

```bash
git checkout step3
```

## Run

From within the `pas-step-by-step` directory, run the following commands to add missing resources (firewall and tags) to existing infrastructure:

```bash
cd terraform/gcp/management/
terraform plan -out plan
terraform apply plan
```
After tags and firewall rule are successfully applied to your infrastructure you must reboot your jumpbox for tags and firewall being activated:

```bash
ssh jbx.${var.env_name}.domain.com
sudo reboot
```
You also need your GCP credentials file to be uploaded to your jumpbox. Once your jumpbox is rebooted, run the following command to upload your gcp credentials file:

```bash
scp ${var.service_account_key} jbx.${var.env_name}.domain.com:gcp_auth.json
```

`${var.service_account_key}` comes from terraform vaiables, so fill with your own file path.

Then from within the `pas-step-by-step` directory, upload create_env.sh script to your jumpbox:

```bash
cd scripts
scp create_env.sh jbx.${var.env_name}.domain.com:
```
Now, from your jumpbox run the following command to create a new bosh directory instance:

```bash
./create_env.sh
```

To verify bosh director is created and fully functional run the following commands from your jumpbox:

```bash
source ~/.boshrc
bosh -e bosh-mgmt env
Using environment '10.0.20.10' as client 'admin'

Name               bosh-mgmt
UUID               e847e297-c35c-460e-a166-a68d60de6b6a
Version            268.6.0 (00000000)
Director Stemcell  ubuntu-xenial/170.9
CPI                google_cpi
Features           compiled_package_cache: disabled
                   config_server: enabled
                   local_dns: enabled
                   power_dns: disabled
                   snapshots: disabled
User               admin

Succeeded
```

You can jump to step4 below!