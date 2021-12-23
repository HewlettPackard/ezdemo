# Ezmeral Container Platform Demo

## on AWS (Azure and Vmware to follow)

Automated installation for Ezmeral Container Platform and MLOps on AWS for demo purposes.

You need docker to run the container. It should work on any docker runtime.

# Usage

Download the [start script](https://raw.githubusercontent.com/hpe-container-platform-community/ezdemo/main/docker-run.sh), or copy/paste below to start the container.

```
#!/usr/bin/env bash

VOLUMES=()
CONFIG_FILES=("aws_config.json" "azure_config.json" "vmware_config.json" "kvm_config.json")
for file in "${CONFIG_FILES[@]}"
do
  target="${file%_*}"
  # [[ -f "./${file}" ]] && VOLUMES="--mount=type=bind,source="$(pwd)"/${file},target=/app/server/${target}/config.json ${VOLUMES}"
  [[ -f "./${file}" ]] && VOLUMES+=("$(pwd)/${file}:/app/server/${target}/config.json:rw")
done

# echo "${VOLUMES[*]}"
printf -v joined ' -v %s' "${VOLUMES[@]}"
# echo "${joined}"
## run at the background with web service exposed at 4000
docker run -d -p 4000:4000 -p 8443:8443 ${joined} erdincka/ezdemo:latest
```

Create "aws_config.json" in the same folder with your settings and credentials. Template provided below:

AWS Template;
```
{
  "aws_access_key": "",
  "aws_secret_key": "",
  "is_mlops": false,
  "user": "",
  "admin_password": "ChangeMe!",
  "is_mapr": false,
  "project_id": ""
}

```

Once the container starts, you can either use the WebUI on http://localhost:4000/ or run scripts manually within the container.

# Advanced Usage

Exec into the container and use scripts provided.

```
docker exec -it "$(docker ps -f "status=running" -f "ancestor=erdincka/ezdemo" -q)" /bin/bash
```

### Run all

```./00-run_all.sh aws```

### Run Individaully

At any stage if script fails or if you wish to update your environment, you can restart the process wherever needed;

- `./01-init.sh aws`
- `./02-apply.sh aws`
- `./03-install.sh aws`
- `./04-configure.sh aws`

Deployed resources will be available in ./server/ansible/inventory.ini file

- All access to the environment is possible only through the gateway

- Use `ssh centos@10.1.0.xx` to access hosts within the container, using their internal IP address (~/.ssh/config setup for jump host via gateway)

- You can copy "./generated/controller.prv_key" and "~/.ssh/config" to your host to use them to access hosts directly

- Copy "./generated/minica.pem" 

# Reference

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

[ ] Add Azure deployment capability

[ ] Add Vmware deployment capability

[ ] Add KVM deployment capability


## Notes

Deployment uses EU-WEST-2 (London) region on AWS
