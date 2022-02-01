variable "user" {}
variable "project_id" {}
variable "admin_password" {}
variable "is_mlops" { default = true }
variable "is_mapr" { default = false }
variable "is_runtime" { default = true }
variable "is_ha" { default = false }

variable "region" { default = "eu-west-2" }
variable "az" { default = "eu-west-2a" }

# variable "centos8_ami" { default = "ami-05cc99c0a1894da6e" }

variable "gtw_instance_type" { default = "m5.xlarge" } ## 4c16
variable "ctr_instance_type" { default = "r5.2xlarge" } ## 8c64

variable "worker_count" { default = 2 }
## GPU Workers
variable "gworker_count" { default = 0 }
variable "gpu_instance_type" { default = "g4dn.4xlarge" } ## 16c 64GB 1T4
# variable "gpu_instance_type" { default = "p3.2xlarge" } ## 8c 61GB 1v100
# variable "gpu_instance_type" { default = "p4d.24xlarge" } ## 96c 1152GB 8a100

variable "mapr_count" { default = 3 }
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

variable "client_cidr_block" { default = "0.0.0.0/0" } ### Access possible via gateway only - for limited ports

