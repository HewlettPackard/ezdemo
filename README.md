### Ezmeral Container Platform Demo

#### on AWS (Azure and Vmware to follow)

Automated installation of Ezmeral Container Platform on AWS for demo purposes.

## Utilities used in the container
* AWS CLI 
* Terraform - to deploy AWS EC2 nodes with CentOS 7.9 image (ami-09e5afc68eed60ef4)
* Ansible - setup and configure ECP & DFK
* python & jq & hpecp

## Settings
You will need your credentials to configure in the web UI

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

## How to run?
Run docker image, it should expose port 3000 (UI) and 3001 (API), then browse to http://localhost:3000.

Click on the provider, enter configuration details and click on "Deploy" button. 

Autoscroll doesn't work in console output, wait until spinner is gone, and retry if any errors are encountered.

Failures will be highlighted at the bottom of the page.


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
