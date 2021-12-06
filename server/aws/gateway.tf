### Gateway Instance

resource "aws_instance" "gateway" {
  count = var.is_ha ? 2 : 1
  ami           = var.centos7_ami
  instance_type = var.gtw_instance_type
  key_name      = aws_key_pair.main.key_name
  vpc_security_group_ids = flatten([
    aws_default_security_group.main.id,
    aws_security_group.main.id,
    aws_security_group.allow_ecp_ports.id // this should be enabled only on gateway
  ])
  subnet_id = aws_subnet.main.id
  user_data = data.template_file.cloud_data.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
    tags = {
      Name            = "${var.project_id}-gateway-${count.index + 1}-root-ebs"
      Project         = var.project_id
      user            = var.user
      deployment_uuid = random_uuid.deployment_uuid.result
    }
  }

  tags = {
    Name            = "${var.project_id}-instance-gateway-${count.index + 1}"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

### OUTPUTS
output "gateway_private_ips" {
  value = [aws_instance.gateway.*.private_ip]
}
output "gateway_private_dns" {
  value = [aws_instance.gateway.*.private_dns]
}
output "gateway_public_ips" {
  value = [aws_instance.gateway.*.public_ip]
}
output "gateway_public_dns" {
  value = [aws_instance.gateway.*.public_dns]
}
output "gateway_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key centos@${aws_instance.gateway.0.public_ip}"
}
