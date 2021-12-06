variable "user" {}
variable "project_id" {}
variable "is_mlops" { default = true }
variable "is_mapr" { default = false }
variable "is_runtime" { default = false }
variable "is_ha" { default = false }

### TODO: allow region selection
variable "region" { default = "eu-west-2" }
variable "az" { default = "eu-west-2a" }
variable "az_id" { default = "euw2-az2" }
variable "centos7_ami" { default = "ami-09e5afc68eed60ef4" }
variable "centos8_ami" { default = "ami-05cc99c0a1894da6e" }
variable "ubuntu_ami" { default = "ami-0f9124f7452cdb2a6" }

variable "ssh_prv_key_path" { default = "./generated/controller.prv_key" }
variable "ssh_pub_key_path" { default = "./generated/controller.pub_key" }

variable "gtw_instance_type" { default = "m5.xlarge" } ## 4 cores 16GB memory
variable "ctr_instance_type" { default = "r5.2xlarge" } ## 8 cores 64GB memory

variable "worker_count" { default = 2 }

variable "mapr_count" { default = 3 }
variable "mapr_instance_type" { default = "m4.4xlarge" }
variable "wkr_instance_type" {
  default = "m4.4xlarge" ## 16 vcores 64GB memory
  # "m5.8xlarge" ## 32 vcores 128GB memory
  # MLOPS worker
  # "r5.2xlarge" ## 8 vcores 64GB memory
  ## GPU Worker
  # "p4d.24xlarge" ## 96 vcores 1152GB memory + 8 A100 GPU
}
variable "ad_instance_type" { default = "t2.small" }

variable "epic_dl_url" { default = "" }

variable "ad_member_group" { default = "DemoTenantUsers" }
variable "ad_admin_group" { default = "DemoTenantAdmins" }

variable "client_cidr_block" { default = "0.0.0.0/0" } ### USING THE DEFAULT IS NOT RECOMMENDED

variable "additional_client_ip_list" { default = [] }
