# ✅ Get the latest Amazon Linux 2023 AMI
data "aws_ami" "get_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al*-ami-2023*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ✅ Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# ✅ Get the subnets in the default VPC
data "aws_subnets" "public" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-kernel-5.10-hvm-x86_64-gp2"
}
