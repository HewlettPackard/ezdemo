// Don't do anything with the default network acl except add tags
// to identify it with this project
// See: https://github.com/terraform-providers/terraform-provider-aws/issues/12219#issuecomment-593453391
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id

  tags = {
    Name            = "${var.project_id}-default-network-acl"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.main.id]
  tags = {
    Name            = "${var.project_id}-network-acl"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_network_acl_rule" "allow_all_in_subnet" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.main.cidr_block
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "allow_ssh_from_client_ips" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.client_cidr_block
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "allow_https_from_client_ips" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.client_cidr_block
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "allow_api_from_client_ips" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.client_cidr_block
  from_port      = 8080
  to_port        = 8080
}

resource "aws_network_acl_rule" "allow_k8s_api_from_client_ips" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 135
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.client_cidr_block
  from_port      = 9500
  to_port        = 9699
}

resource "aws_network_acl_rule" "allow_mapped_from_client_ips" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 140
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.client_cidr_block
  from_port      = 10000
  to_port        = 50000
}

resource "aws_network_acl_rule" "allow_return_traffic" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

// egress

resource "aws_network_acl_rule" "allow_any_outgoing_traffic_to_internet" {
  # allow internet access from instances 
  network_acl_id = aws_network_acl.main.id
  rule_number    = 150
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}
