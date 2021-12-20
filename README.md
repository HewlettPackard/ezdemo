# Ezmeral Container Platform Demo

## on AWS (Azure and Vmware to follow)

Automated installation for Ezmeral Container Platform and MLOps on AWS for demo purposes.

# Settings
You will need your credentials to configure in the web UI or within ./server/**provider**/config.json (template file provided)

```
"aws_access_key_id": "<your key>",
"aws_secret_access_key": "<your secret>",
"is_mlops": true,
"project_id": "myuser-demo",
"user": "myuser"
```

# Usage

This is planned to run within a container, with all tools, utilities pre-packaged. It has two parts, web-UI for user friendly installation, and a server process running as API server to accept and run commands.

```docker run -d -p 4000:4000 erdincka/ezdemo:latest``` and connect to http://localhost:4000/


You can also manually use the scripts through the UI or simply via CLI.

## Manually running via UI:
- ```git clone https://github.com/hpe-container-platform-community/ezdemo```

- ```cd ezdemo```

- Run the server ```python3 server/main.py``` (not needed if you plan to use the CLI method)

## Using via CLI:
- ```git clone https://github.com/hpe-container-platform-community/ezdemo```

- edit `./server/aws/config.json-template`
  - set admin password (*admin_pass*), used for ECP admin user and Minio admin user (where deployed)
  - add your aws credentials (*aws_access_key* and *aws_secret_key*)
  - project tag details (*project_id* and *user*)
  - is_mlops (*true* or *false*, without quotes)
  and save it as `config.json` in the same directory

** Enable/disable MLOps deployment with "is_mlops" key (when set to true, this will create a tenant and configure it with kubeflow/mlflow)

- ```./00-run_all.sh aws```

- At any stage if script fails or if you wish to update your environment, you can restart the process wherever needed;

  - `./01-init.sh aws`
  - `./02-apply.sh aws`
  - `./03-install.sh aws`
  - `./04-configure.sh aws`

- Deployed resources will be available in ./server/ansible/inventory.ini file

  - ssh access only through gateway
  
  - use `ssh centos@10.1.0.xx` to access any host via their AWS internal IP address (~/.ssh/config setup for jump host via gateway)

## Utilities used in the container (or you need if you are running locally)
* AWS CLI - Download from [AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* Terraform - Download from [Terraform](https://www.terraform.io/downloads.html)
* Ansible - Install from [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) or simply via pip (sudo pip3 install ansible)
* python3 (apt/yum/brew install python3)
* jq (apt/yum/brew install jq)
* hpecp (pip3 install hpecp)
* kubectl from [K8s](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

## Scripts
* 00-run_all.sh: Runs all scripts at once (unattended install)
* 01-init.sh: Initialize Terraform, create SSH keys & certificates
* 02-apply.sh: Runs `terraform apply` to deploy resources
* 03-install.sh: Run Ansible scripts to install ECP
* 04-configure.sh: Run Ansible scripts to configure ECP for demo

* 99-destroy.sh: Destroy all created resources on AWS (** DANGER **: All resources will be destroyed, except the generated keys and certificates)


## Ansible Scripts

Courtesy of Dirk Derichsweiler (https://github.com/dderichswei).

  - prepare_centos: Updates packages and requirements for ECP installation

  - install_falco: Updates kernel and install falco service

  - install_ecp: Initial installation and setup for ECP

  - import_hosts: Collects node information and update them as ECP worker nodes

  - create_k8s: Installs Kubernetes Cluster (if MLOps is not selected)

  - create_picasso: Installs Kubernetes Cluster and Picasso (Data Fabric on Kubernetes)

  - configure_picasso: Enables Picasso (Data Fabric on Kubernetes) for all tenants

  - configure_mlops: Configures MLOps tenant and life-cycle tools (Kubeflow, Minio, Jupyter NB etc)

# TO-DO
[X] External DF deployment

[ ] Use GPU workers

[X] Dockerfile to containerise this tool

[ ] Add Azure/KVM/VMWare deployment capability


## Notes

Deployment uses EU-WEST-2 (London) region on AWS
