/******************* VPC ********************/

resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name            = "${var.project_id}-vpc"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

data "aws_availability_zone" "main" {
  name = var.az
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.0.0/24"
  availability_zone_id    = data.aws_availability_zone.main.zone_id
  map_public_ip_on_launch = true

  tags = {
    Name            = "${var.project_id}-subnet"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

/******************* Route Table ********************/

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name            = "${var.project_id}-main-route-table"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_route" "main" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

/******************* Internet Gateway ********************/

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name            = "${var.project_id}-internet-gateway"
    Project         = var.project_id
    user            = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

### OUTPUTS
# output "client_cidr_block" {
#   value = var.client_cidr_block
# }
