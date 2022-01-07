# Configure the AWS Provider
provider "aws" {
  region                  = var.region
  shared_credentials_file = "./credentials"
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
