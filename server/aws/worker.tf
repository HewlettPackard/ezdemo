# Worker instances

locals {
  worker_count = var.is_runtime ? var.worker_count + (var.is_mlops ? 3 : 0) : 0
}

resource "aws_instance" "workers" {
  count         = local.worker_count
  ami           = var.EC2_CENTOS7_AMIS[var.region]
  instance_type = var.wkr_instance_type
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
      Name            = "${var.project_id}-worker-${count.index + 1}-root-ebs"
      Project         = var.project_id
      user            = var.user
      deployment_uuid = random_uuid.deployment_uuid.result
    }
  }

  tags = {
    Name            = "${var.project_id}-worker-${count.index + 1}"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

# /dev/sdb
resource "aws_ebs_volume" "worker-ebs-volumes-sdb" {
  count             = local.worker_count
  availability_zone = var.az
  size              = 500
  type              = "gp2"

  tags = {
    Name            = "${var.project_id}-worker-${count.index + 1}-ebs-sdb"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_volume_attachment" "worker-volume-attachment-sdb" {
  count       = local.worker_count
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.worker-ebs-volumes-sdb.*.id[count.index]
  instance_id = aws_instance.workers.*.id[count.index]
  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdc
resource "aws_ebs_volume" "worker-ebs-volumes-sdc" {
  count             = local.worker_count
  availability_zone = var.az
  size              = 500
  type              = "gp2"
  tags = {
    Name            = "${var.project_id}-worker-${count.index + 1}-ebs-sdc"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}
resource "aws_volume_attachment" "worker-volume-attachment-sdc" {
  count       = local.worker_count
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.worker-ebs-volumes-sdc.*.id[count.index]
  instance_id = aws_instance.workers.*.id[count.index]
  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}
### OUTPUTS
output "workers_private_ip" {
  value = [aws_instance.workers.*.private_ip]
}
output "workers_private_dns" {
  value = [aws_instance.workers.*.private_dns]
}
output "worker_count" {
  value = local.worker_count
}

