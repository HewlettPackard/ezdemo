# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.2.0"
    }
  }
}

provider "aws" {
  region                  = var.region
  shared_config_files      = ["./config"]
  shared_credentials_files = ["./credentials"]
  profile                 = "default"
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_id}-keypair"
  public_key = file("../generated/controller.pub_key")
}

resource "random_uuid" "deployment_uuid" {}

data "template_file" "cloud_data" {
  template = file("../generated/cloud-init.yaml")
}
