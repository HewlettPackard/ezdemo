### AD Instance

resource "aws_instance" "ad_server" {
  ami           = data.aws_ami.ec2_centos7_ami.image_id
  instance_type = var.ad_instance_type
  key_name      = aws_key_pair.main.key_name
  vpc_security_group_ids = flatten([
    aws_default_security_group.main.id,
    aws_security_group.main.id
  ])
  subnet_id        = aws_subnet.main.id
  
  root_block_device {
    volume_type = "gp2"
    volume_size = 400
    delete_on_termination = true
    tags = {
      Name            = "${var.project_id}-ad-server-root-ebs"
      Project         = var.project_id
      user            = var.user
      deployment_uuid = random_uuid.deployment_uuid.result
    }
  }

  tags = {
    Name            = "${var.project_id}-ad-server"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

### OUTPUTS
output "ad_server_private_ip" {
  value = aws_instance.ad_server.private_ip
}
