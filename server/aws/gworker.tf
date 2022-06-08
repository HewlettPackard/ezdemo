# GPU Worker instances

resource "aws_instance" "gworkers" {
  count         = var.gworker_count
  ami           = data.aws_ami.ec2_centos7_ami.image_id
  instance_type = var.gpu_instance_type
  key_name      = aws_key_pair.main.key_name
  vpc_security_group_ids = flatten([
    aws_default_security_group.main.id,
    aws_security_group.main.id
  ])
  subnet_id = aws_subnet.main.id

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
    delete_on_termination = true
    tags = {
      Name            = "${var.project_id}-gworker-${count.index + 1}-root-ebs"
      Project         = var.project_id
      user            = var.user
      deployment_uuid = random_uuid.deployment_uuid.result
    }
  }

  tags = {
    Name            = "${var.project_id}-gworker-${count.index + 1}"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

# /dev/sdb
resource "aws_ebs_volume" "gworker-ebs-volumes-sdb" {
  count             = var.gworker_count
  availability_zone = var.az
  size              = 500
  type              = "gp2"

  tags = {
    Name            = "${var.project_id}-gworker-${count.index + 1}-ebs-sdb"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_volume_attachment" "gworker-volume-attachment-sdb" {
  count       = var.gworker_count
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.gworker-ebs-volumes-sdb.*.id[count.index]
  instance_id = aws_instance.gworkers.*.id[count.index]
  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdc
resource "aws_ebs_volume" "gworker-ebs-volumes-sdc" {
  count             = var.gworker_count
  availability_zone = var.az
  size              = 500
  type              = "gp2"
  tags = {
    Name            = "${var.project_id}-gworker-${count.index + 1}-ebs-sdc"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}
resource "aws_volume_attachment" "gworker-volume-attachment-sdc" {
  count       = var.gworker_count
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.gworker-ebs-volumes-sdc.*.id[count.index]
  instance_id = aws_instance.gworkers.*.id[count.index]
  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}
### OUTPUTS
output "gworker_private_ips" {
  value = aws_instance.gworkers.*.private_ip
}
output "gworkers_private_dns" {
  value = aws_instance.gworkers.*.private_dns
}
output "gworker_count" {
  value = var.gworker_count
}
