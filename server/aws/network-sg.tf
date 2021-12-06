# Don't do anything with the default sg except add tags
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name            = "${var.project_id}-default-security-group"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_security_group" "main" {
  vpc_id      = aws_vpc.main.id
  name        = "main"
  description = "main"

  tags = {
    Name            = "${var.project_id}-main-security-group"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_security_group_rule" "internal_host_to_host_access" {
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
}

resource "aws_security_group_rule" "return_traffic" {
  security_group_id = aws_security_group.main.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

// allow selective traffic from specified ips
resource "aws_security_group" "allow_ecp_ports" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_ecp_ports"
  description = "allow_ecp_ports"
  depends_on  = [aws_vpc.main]

  tags = {
    Name            = "${var.project_id}-allow-ssh-https-api-from-specified-ips-security-group"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr_block]
    from_port   = 22
    to_port     = 22
  }
  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr_block]
    from_port   = 443
    to_port     = 443
  }
  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr_block]
    from_port   = 8080
    to_port     = 8080
  }
  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr_block]
    from_port   = 8443
    to_port     = 8443
  }
  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr_block]
    from_port   = 10000
    to_port     = 50000
  }
}