resource "aws_instance" "springboot_app" {
  ami                    = data.aws_ami.get_ami.id
  instance_type          = var.instance_type
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

      # Disable automatic background updates (Amazon Linux 2023)
      "sudo systemctl stop dnf-automatic.timer || true",
      "sudo systemctl disable dnf-automatic.timer || true",

      # Wait for dnf lock to clear
      "echo 'Checking for DNF lock...'",
      "for i in {1..60}; do",
      "  sudo lsof /var/cache/dnf/lock >/dev/null 2>&1 || break",
      "  echo 'Waiting for dnf lock...'; sleep 5",
      "done",

      # Update and install dependencies
      "sudo dnf makecache --refresh -y",
      "sudo dnf install -y java-21-amazon-corretto maven git",

      # Clone and build the Spring Boot application
      "git clone https://github.com/nldblanch/cacs-checklist.git /home/ec2-user/app",
      "cd /home/ec2-user/app",
      "chmod +x ./mvnw",
      "./mvnw clean package -DskipTests",

      # Find and run the JAR
      "JAR=$(find target -name '*.jar')",
      "nohup java -jar $JAR > app.log 2>&1 &"
    ]
  }
}
