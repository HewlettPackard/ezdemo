# Worker instances
resource "aws_instance" "mapr" {
  count         = var.is_mapr ? var.mapr_count : 0
  ami           = var.ubuntu_ami
  instance_type = var.mapr_instance_type
  key_name      = aws_key_pair.main.key_name
  vpc_security_group_ids = flatten([
    aws_default_security_group.main.id,
    aws_security_group.main.id
  ])
  subnet_id = aws_subnet.main.id
  user_data = data.template_file.cloud_data.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
    tags = {
      Name            = "${var.project_id}-mapr-${count.index + 1}-root-ebs"
      Project         = var.project_id
      user            = var.user
      deployment_uuid = random_uuid.deployment_uuid.result
    }
  }

  tags = {
    Name            = "${var.project_id}-mapr-${count.index + 1}"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

# /dev/sdb
resource "aws_ebs_volume" "mapr-ebs-volumes-sdb" {
  count             = var.is_mapr ? var.mapr_count : 0
  availability_zone = var.az
  size              = 500
  type              = "gp2"

  tags = {
    Name            = "${var.project_id}-mapr-${count.index + 1}-ebs-sdb"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_volume_attachment" "mapr-volume-attachment-sdb" {
  count       = var.is_mapr ? var.mapr_count : 0
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.mapr-ebs-volumes-sdb.*.id[count.index]
  instance_id = aws_instance.mapr.*.id[count.index]
  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdc
resource "aws_ebs_volume" "mapr-ebs-volumes-sdc" {
  count             = var.is_mapr ? var.mapr_count : 0
  availability_zone = var.az
  size              = 500
  type              = "gp2"
  tags = {
    Name            = "${var.project_id}-mapr-${count.index + 1}-ebs-sdc"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}
resource "aws_volume_attachment" "mapr-volume-attachment-sdc" {
  count       = var.is_mapr ? var.mapr_count : 0
  device_name = "/dev/xvdc"
  volume_id   = aws_ebs_volume.mapr-ebs-volumes-sdc.*.id[count.index]
  instance_id = aws_instance.mapr.*.id[count.index]
  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}
### OUTPUTS
output "mapr_private_ips" {
  value = [aws_instance.mapr.*.private_ip]
}
# output "mapr_private_dns" {
#   value = [aws_instance.mapr.*.private_dns]
# }
output "mapr_count" {
  value = var.is_mapr ? var.mapr_count : 0
}
