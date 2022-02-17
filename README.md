# Ezmeral Container Platform Demo

Automated installation for Ezmeral Container Platform and MLOps on various platforms (available on AWS and Azure) for demo purposes.

You need a container runtime to run tool. It should work on any container runtime and tested on Docker. Podman doesn't work if you try to map volumes (should work fine without the mounts).

## Usage

Download the [start script](https://raw.githubusercontent.com/hpe-container-platform-community/ezdemo/main/start.sh), or copy/paste below to start the container.

```bash
#!/usr/bin/env bash
VOLUMES=()
CONFIG_FILES=("aws_config.json" "azure_config.json" "vmware_config.json" "kvm_config.json")
for file in "${CONFIG_FILES[@]}"
do
  target="${file%_*}"
  [[ -f "./${file}" ]] && VOLUMES+=("$(pwd)/${file}:/app/server/${target}/config.json:rw")
done
printf -v joined ' -v %s' "${VOLUMES[@]}"
docker run --pull always -d -p 4000:4000 -p 8443:8443 ${joined} erdincka/ezdemo:latest
```

Create "aws_config.json" or "azure_config.json" in the same folder with your settings and credentials. Template provided below:

AWS Template;

```json
{
  "aws_access_key": "",
  "aws_secret_key": "",
  "project_id": "",
  "user": "",
  "admin_password": "ChangeMe!",
  "is_mlops": false,
  "is_mapr": false,
  "is_gpu": false,
  "is_ha": false,
  "region": ""
}
```

Azure Template;

```json
{
  "subscription": "",
  "appId": "",
  "password": "",
  "tenant": "",
  "project_id": "",
  "user": "",
  "admin_password": "ChangeMe!",
  "is_mlops": false,
  "is_mapr": false,
  "is_gpu": false,
  "is_ha": false,
  "region": ""
}
```

Once the container starts, you can either use the WebUI on <http://localhost:4000/> or run scripts manually within the container.

## Advanced Usage

Exec into the container and use scripts provided.

```bash
docker exec -it "$(docker ps -f "status=running" -f "ancestor=erdincka/ezdemo" -q)" /bin/bash
```

### Run all

```./00-run_all.sh aws|azure|vmware|kvm|mac```

### Run Individaully

At any stage if script fails or if you wish to update your environment, you can restart the process wherever needed;

- `./01-init.sh aws|azure|vmware|kvm|mac` **MacOS target is experimental, and has undocumented prerequisites**
- `./02-apply.sh aws|azure|vmware|kvm|mac`
- `./03-install.sh aws|azure|vmware|kvm|mac`
- `./04-configure.sh aws|azure|vmware|kvm|mac`

Deployed resources will be available in ./server/ansible/inventory.ini file

- All access to the environment is possible only through the gateway

- Use `ssh centos@10.1.0.xx` to access hosts within the container, using their internal IP address (~/.ssh/config setup for jump host via gateway)

- You can copy "./generated/controller.prv_key" and "~/.ssh/config" to your workstation to access the deployed nodes directly

- Copy and install "./generated/*/minica.pem" into your browser to prevent SSL certificate errors

## Reference

### Utilities used in the container (or you need if you are running locally)

- AWS CLI - Download from [AWS](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Azure-CLI - Download from [Azure](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Terraform - Download from [Terraform](https://www.terraform.io/downloads.html)
- Ansible - Install from [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) or simply via pip (sudo pip3 install ansible)
- python3 (apt/yum/brew install python3)
- jq (apt/yum/brew install jq)
- hpecp (pip3 install hpecp)
- kubectl from [K8s](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- minica (apt/yum/brew install minica)

### Scripts

- 00-run_all.sh: Runs all scripts at once (unattended install)
- 01-init.sh: Initialize Terraform, create SSH keys & certificates
- 02-apply.sh: Runs `terraform apply` to deploy resources
- 03-install.sh: Run Ansible scripts to install ECP
- 04-configure.sh: Run Ansible scripts to configure ECP for demo
- 99-destroy.sh: Destroy all created resources (**DANGER**: All resources will be destroyed, except the generated keys and certificates)

### Ansible Scripts

Courtesy of Dirk Derichsweiler (<https://github.com/dderichswei>).

- prepare_centos: Updates packages and requirements for ECP installation
- install_falco: Updates kernel and install falco service
- install_ecp: Initial installation and setup for ECP
- import_hosts: Collects node information and update them as ECP worker nodes
- create_k8s: Installs Kubernetes Cluster (if MLOps is not selected)
- create_picasso: Installs Kubernetes Cluster and Picasso (Data Fabric on Kubernetes)
- configure_picasso: Enables Picasso (Data Fabric on Kubernetes) for all tenants
- configure_mlops: Configures MLOps tenant and life-cycle tools (Kubeflow, Minio, Jupyter NB etc)

## Notes

Deployment defaults to EU-WEST-2 (EU - London) region on AWS, UK South (EU - London) region on Azure.

Please use following format to choose your region on AWS (config.json);

```shell
"us-east-1"      // N.Virginia
"us-east-2"      // Ohio
"us-west-1"      // N.California
"us-west-2"      // Oregon
"ap-southeast-1" // Singapore
"eu-central-1"   // Frankfurt
"eu-west-1"      // Ireland
"eu-west-2"      // London
"eu-west-3"      // Paris
"eu-north-1"     // Stockholm
"ca-central-1"   // Montréal, Québec
```

This format should be used to select a region on Azure;

```shell
"eastus"
"eastus2"
"centralus"
"westus"
"westus2"
"canadacentral"
"canadaeast"
"northeurope"
"westeurope"
"ukwest"
"uksouth"
"francecentral"
"germanynorth"
"centralindia"
"japaneast"
"australiacentral"
"uaenorth"
"southafricawest"
```

** Not all regions are tested, please provide feedback if you have an issue with a region.
