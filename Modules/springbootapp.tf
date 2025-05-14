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
      "echo 'Updating system...'",
      "sudo yum update -y",

      "echo 'Installing Java 21...'",
      "sudo yum clean metadata || echo 'Metadata clean failed'",
      "sudo yum install -y java-21-amazon-corretto || echo 'Java install failed'",

      "echo 'Installing Maven and Git...'",
      "sudo yum install -y maven git || echo 'Maven/Git install failed'",

      "echo 'Cloning app repo...'",
      "git clone https://github.com/nldblanch/cacs-checklist.git /home/ec2-user/app || echo 'Git clone failed'",
      "cd /home/ec2-user/app",

      "echo 'Building app with Maven...'",
      "./mvnw clean package -DskipTests || echo 'Maven build failed'",

      "echo 'Running app with nohup...'",
      "nohup java -jar target/*SNAPSHOT.jar > app.log 2>&1 & || echo 'App failed to start'",

      "echo 'Provisioning complete.'"
    ]
  }

}
