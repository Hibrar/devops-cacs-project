resource "aws_instance" "springboot_app" {
  ami                    = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  iam_instance_profile   = aws_iam_instance_profile.cacs_instance_profile.name

  tags = {
    Name = "springboot-app"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.ssh_private_key
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",

      # Disable auto updates to avoid yum lock (for Amazon Linux 2023)
      "echo 'Disabling automatic updates...'",
      "sudo systemctl stop dnf-automatic.timer || true",
      "sudo systemctl disable dnf-automatic.timer || true",

      # Wait for yum lock to clear
      "echo 'Checking for YUM lock...'",
      "while sudo fuser /var/run/yum.pid >/dev/null 2>&1; do echo 'Waiting for yum lock...'; sleep 5; done",

      "echo 'Updating system...'",
      "sudo yum update -y",

      "echo 'Installing Java 21...'",
      "sudo yum install -y java-21-amazon-corretto",

      "echo 'Installing Maven and Git...'",
      "sudo yum install -y maven git",

      "echo 'Cloning GitHub repo...'",
      "git clone https://github.com/nldblanch/cacs-checklist.git /home/ec2-user/app",

      "cd /home/ec2-user/app",
      "chmod +x ./mvnw",
      "echo 'Building app...'",
      "./mvnw clean package -DskipTests",

      "echo 'Running Spring Boot app...'",
      "JAR=$(find target -name '*.jar')",
      "nohup java -jar $JAR > app.log 2>&1 &",

      "echo 'Provisioning complete.'"
    ]
  }
}
