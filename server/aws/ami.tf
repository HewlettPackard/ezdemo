data "aws_ami" "ec2_centos7_ami" {
  most_recent      = true
  owners           = ["aws-marketplace"]
  filter {
    name   = "product-code"
    values = ["cvugziknvmxgqna9noibqnnsy"]
  }
}

data "aws_ami" "ec2_centos8_ami" {
  most_recent      = true
  owners           = ["aws-marketplace"]
  filter {
    name   = "product-code"
    values = ["47k9ia2igxpcce2bzo8u3kj03"]
  }
}
