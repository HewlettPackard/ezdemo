data "aws_ami" "ec2_centos7_ami" {
  most_recent      = true
  owners           = ["aws-marketplace"]
  filter {
    name   = "product-code"
    values = ["cvugziknvmxgqna9noibqnnsy"]
  }
}
