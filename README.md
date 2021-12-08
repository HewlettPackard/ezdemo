### Ezmeral Container Platform Demo

#### on AWS (Azure and Vmware to follow)

Automated installation of Ezmeral Container Platform on AWS for demo purposes.

### Usage

This is planned to run within a container, with all tools, utilities pre-packaged. It has two parts, web-UI for user friendly installation, and a server process running as API server to accept and run commands.

```docker run -d -p 3000:3000 -p 3001:3001 erdincka/ezdemo:latest``` and connect to http://localhost:3000/


You can also manually use the scripts through the UI or simply via CLI.

#### Testing or manually running via UI:
- ```git clone https://github.com/hpe-container-platform-community/ezmeral-demo```

- ```cd ezmeral-demo```

- ```yarn start``` for webUI (not needed if you plan to use the CLI method)

- Open another terminal run the server ```python3 server/main.py``` (not needed if you plan to use the CLI method)

#### Testing or using via CLI:
- ```git clone https://github.com/hpe-container-platform-community/ezmeral-demo```

- edit `./server/aws/config.json-template` with your aws credentials and project tag details, and save it as `config.json` in the same directory

  - enable/disable MLOps deployment with "is_mlops" key (if set to false, this will skip steps to create a tenant and configure it with kubeflow/mlflow)

- ```./00-run_all.sh aws```

- At any stage if script fails or if you wish to update your environment, you can restart the process wherever needed;

  - `./01-init.sh aws`
  - `./02-apply.sh aws`
  - `./03-install.sh aws`
  - `./04-configure.sh aws`

- Deployed resources will be available in ./server/ansible/inventory.ini file

  - ssh access only through gateway
  
  - use `./generated/ssh_host.sh centos@10.1.0.xx` to access any host via their AWS internal IP address

## Utilities used in the container (or you need if you are running locally)
* AWS CLI - Download from [AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* Terraform - Download from [Terraform](https://www.terraform.io/downloads.html)
* Ansible - Install from [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) or simply via pip (sudo pip3 install ansible)
* python3 (apt/yum/brew install python3)
* jq (apt/yum/brew install jq)
* hpecp (pip3 install hpecp)

## Settings
You will need your credentials to configure in the web UI or within ./server/<provider>/config.json (template file provided)

```
aws_access_key_id=<your key>

aws_secret_access_key=<your secret>
```

## Scripts

* 01-init: Initialize Terraform, create SSH keys & certificates
* 02-apply: Terraform apply to deploy resources, using cloud-init
  - Active Directory node deployment within cloud-init
* 03-install: Run Ansible scripts to install ECP
* 04-configure: Run Ansible scripts to configure ECP for demo

* 99-destroy: Destroy all created resources on AWS


## Ansible Scripts
Thanks to Dirk(https://github.com/dderichswei)

prepare_centos: Update packages and requirements for HCP installation

install_falco: Update kernel and install falco service

install_hcp: Initial installation and setup for ECP

import_hosts: Collect node information and update them for K8s and Picasso clusters

create_picasso: Install Picasso (DF on Kubernetes) on selected nodes (min 4 required - 3 masters and 1 worker for addo-ns)

configure_picasso: Enable Picasso/DF for all tenants

configure_mlops: Deploy MLOps life-cycle tools

## TO-DO
[ ] External DF deployment

[ ] Use GPU workers

[ ] Dockerfile to containerise this tool

[ ] Add Azure/KVM/VMWare deployment capability

### Notes

Deployment uses EU-WEST-2 (London) region on AWS
