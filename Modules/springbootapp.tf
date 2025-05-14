# EC2 Instance to run Spring Boot app
resource "aws_instance" "springboot_app" {
  ami                    = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  iam_instance_profile   = aws_iam_instance_profile.cacs_instance_profile.name

  tags = {
    Name = "springboot-app"
  }

  # SSH connection details
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.ssh_private_key
    host        = self.public_ip
  }

  # Commands to run on the EC2 instance
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo 'Start provisioning...'",

      "sudo yum update -y",
      "sudo yum install -y java-21-amazon-corretto || echo 'Java install failed' && exit 2",
      "java -version || echo 'Java version check failed' && exit 2",

      "sudo yum install -y maven git || echo 'Maven/Git install failed' && exit 2",

      "git clone https://github.com/nldblanch/cacs-checklist.git /home/ec2-user/app || echo 'Git clone failed' && exit 2",
      "cd /home/ec2-user/app",

      "./mvnw clean package -DskipTests || echo 'Maven build failed' && exit 2",

      "ls target",
      "JAR=$(find target -name '*.jar') || echo 'JAR not found' && exit 2",
      "echo 'Running $JAR'",
      "nohup java -jar $JAR > app.log 2>&1 &",

      "echo 'Provisioning completed successfully.'"
    ]

  }

}
