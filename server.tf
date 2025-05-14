terraform {
  required_providers {
  aws = {
    source = "hashicorp/aws"
    version = "5.95.0"
    }
  vault = {
    source = "hashicorp/vault"
    version = "4.5.0"
    }
  }
}

data "aws_ami" "get_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al*-ami-2023*-kernel-*-x86_64"]
  }
}

resource "aws_security_group" "allow_tls" {
  name = "Allow TLS"

  dynamic "ingress" {
    for_each = [80, 443, 22]
    content {
      description = "TLS"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_app" {
  ami = data.aws_ami.get_ami.id

  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]

    key_name = "ssh_key"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("C:\\Users\\GoraN\\.ssh\\ssh_key.pem")
      host        = self.public_ip
    }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y nginx",
      "sudo yum install -y git",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "cd /usr/share/nginx/html",
      "sudo rm -rf *",
      "sudo git clone https://github.com/nldblanch/cacs-checklist-playground",
      "cd cacs-checklist-playground/src/main/resources/templates",
      "sudo mv * /usr/share/nginx/html",
      "cd /usr/share/nginx/html",
      "sudo systemctl restart nginx"
    ]
  }
}