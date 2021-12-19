variable "user" {}
variable "project_id" {}
variable "admin_pass" {}
variable "is_mlops" { default = true }
variable "is_mapr" { default = false }
variable "is_runtime" { default = false }
variable "is_ha" { default = false }

### TODO: allow region selection
variable "region" { default = "eu-west-2" }
variable "az" { default = "eu-west-2a" }
variable "az_id" { default = "euw2-az2" }
variable "centos7_ami" { default = "ami-0bab5c8be0975423b" }
variable "centos8_ami" { default = "ami-05cc99c0a1894da6e" }
variable "ubuntu_ami" { default = "ami-0f9124f7452cdb2a6" }

variable "ssh_prv_key_path" { default = "./generated/controller.prv_key" }
variable "ssh_pub_key_path" { default = "./generated/controller.pub_key" }

variable "gtw_instance_type" { default = "m5.xlarge" } ## 4c16
variable "ctr_instance_type" { default = "r5.2xlarge" } ## 8c64

variable "worker_count" { default = 2 }

variable "mapr_count" { default = 1 }
variable "mapr_instance_type" { default = "m4.4xlarge" } 

# c5.8xlarge (32c64)
# "m5.8xlarge" ## 32c128
# MLOPS worker
# "r5.2xlarge" ## 8c64
## GPU Worker
# "p4d.24xlarge" ## 96c1152 + 8 A100 GPU
variable "wkr_instance_type" {
  default = "c5a.8xlarge" ## 32c64
}
variable "ad_instance_type" { default = "t2.small" }

variable "epic_dl_url" { default = "" }

variable "ad_member_group" { default = "DemoTenantUsers" }
variable "ad_admin_group" { default = "DemoTenantAdmins" }

variable "client_cidr_block" { default = "0.0.0.0/0" } ### USING THE DEFAULT IS NOT RECOMMENDED

variable "additional_client_ip_list" { default = [] }
