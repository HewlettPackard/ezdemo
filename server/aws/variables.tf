variable "user" {}
variable "project_id" {}
variable "admin_password" {}
variable "is_mlops" { default = true }
variable "is_mapr" { default = false }
variable "is_runtime" { default = false }
variable "is_ha" { default = false }

### TODO: allow region selection
variable "region" { default = "eu-west-1" }
variable "az" { default = "eu-west-1a" }
# variable "centos7_ami" { default = "ami-0bab5c8be0975423b" }
# variable "centos7_pv_ami" { default = "ami-00846a67" }
variable "centos8_ami" { default = "ami-05cc99c0a1894da6e" }

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

variable "client_cidr_block" { default = "0.0.0.0/0" } ### USING THE DEFAULT IS NOT RECOMMENDED

variable "EC2_CENTOS7_AMIS" {
  # Find more at https://console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images;search=aws-marketplace/CentOS%20Linux%207%20x86_64%20HVM%20EBS%20ENA%201805_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-77ec9308.4
  default = { 
    us-east-1      = "ami-011939b19c6bd1492" # N.Virginia ami-9887c6e7
    us-east-2      = "ami-02cae3195fa1622a8" # Ohio ami-e1496384
    us-west-1      = "ami-00008506813cea27a" # N.California ami-4826c22b
    us-west-2      = "ami-0a4497cbe959da512" # Oregon ami-3ecc8f46
    ap-southeast-1 = "ami-0b6e567c5d6571739" # Singapore ami-8e0205f2
    eu-central-1   = "ami-0c239ecd40dcc174c" # Frankfurt ami-dd3c0f36
    eu-west-1      = "ami-05a178e6f938f2c39" # Ireland  ami-3548444c
    eu-west-2      = "ami-0bab5c8be0975423b" # London ami-00846a67
    eu-west-3      = "ami-0359e47f84edf87e7" # Paris ami-262e9f5b
    eu-north-1     = "ami-0d1ff703c259471e9" # Stockholm ami-b133bccf
    ca-central-1   = "ami-05555f3106026cbf4" # Canada ami-e802818c
  } 
}
