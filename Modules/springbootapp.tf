# ✅ Fetch latest Amazon Linux 2023 AMI via SSM
data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ✅ EC2 Instance to run Spring Boot app
resource "aws_instance" "springboot_app" {
  ami                         = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.allow_tls.id]
  iam_instance_profile        = aws_iam_instance_profile.cacs_instance_profile.name

  tags = {
    Name = "springboot-app"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.ssh_private_key
      host        = self.public_ip
    }

    inline = [
      "set -e",

      # ✅ Update system
      "sudo yum update -y",

      # ✅ Install Java 17
      "sudo yum install -y java-17-amazon-corretto",
      "java -version",

      # ✅ Install Maven
      "sudo yum install -y maven",

      # ✅ Install Git and clone the Spring Boot repo
      "sudo yum install -y git",
      "git clone https://github.com/nldblanch/cacs-checklist.git springboot-app",

      # ✅ Navigate to project and build the JAR
      "cd springboot-app/backend",
      "mvn clean package -DskipTests",

      # ✅ Run the Spring Boot JAR (background)
      "nohup java -jar target/*.jar > output.log 2>&1 &"
    ]
  }
}
