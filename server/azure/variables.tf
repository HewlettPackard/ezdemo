## User provided settings/selections
variable "user" { }
variable "project_id" { }
variable "admin_password" {}

variable "is_mlops" { default = true }
variable "is_mapr" { default = false }
variable "is_runtime" { default = false }
variable "is_ha" { default = false }

# AzureRM settings
variable "region" { default = "uksouth" }
variable "subscription_id" { }
variable "client_id" { }
variable "client_secret" { }
variable "tenant_id" { }

variable "admin_user" { default = "centos" }

variable "vpc_cidr_block" { default = "10.1.0.0/16" } 
variable "subnet_cidr_block" { default = "10.1.0.0/24" }

variable "ssh_prv_key_path" { default = "../generated/controller.prv_key" }
variable "ssh_pub_key_path" { default = "../generated/controller.pub_key" }

variable "cloud_init_file" { default = "../generated/cloud-init.yaml" }

variable "worker_count" { default = 3 }

# variable "gtw_instance_type" { default = "Standard_B16ms" } ## 16c 64GB
variable "gtw_instance_type" { default = "Standard_B4ms" } ## 4c 16GB
variable "ctr_instance_type" { default = "Standard_B20ms" } ## 20c 80GB
# variable "ctr_instance_type" { default = "Standard_A8m_v2" } ## 8c 64GB
variable "wkr_instance_type" { default = "Standard_B20ms" } ## 20c 80GB
# variable "wkr_instance_type" { default = "Standard_A8m_v2" } ## 8c 64GB
variable "ad_instance_type" { default = "Standard_B1ms" } ## 1c 2GB

variable "mapr_count" { default = 1 }
variable "mapr_instance_type" { default = "Standard_B20ms" } ## 20c 80GB
# variable "mapr_instance_type" { default = "Standard_A4m_v2" } ## 4c 32GB

variable "ad_member_group" { default = "DemoTenantUsers" }
variable "ad_admin_group" { default = "DemoTenantAdmins" }
