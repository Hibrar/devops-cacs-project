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

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.ssh_private_key
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",

      # Wait for yum lock to clear (max 5 minutes)
      "echo 'Checking for yum lock...'",
      "for i in {1..60}; do",
      "  if sudo fuser /var/run/yum.pid >/dev/null 2>&1; then",
      "    echo 'yum is locked... waiting 5s'",
      "    sleep 5",
      "  else",
      "    break",
      "  fi",
      "done",

      "echo 'Updating system...'",
      "sudo yum update -y",

      "echo 'Installing Java 21...'",
      "sudo yum install -y java-21-amazon-corretto || (echo 'Java install failed' && exit 2)",
      "java -version || (echo 'Java not found' && exit 2)",

      "echo 'Installing Maven and Git...'",
      "sudo yum install -y maven git || (echo 'Maven/Git install failed' && exit 2)",
      "mvn -v || (echo 'Maven not found' && exit 2)",

      "echo 'Cloning GitHub repo...'",
      "git clone https://github.com/nldblanch/cacs-checklist.git /home/ec2-user/app || (echo 'Git clone failed' && exit 2)",
      "cd /home/ec2-user/app",

      "echo 'Building app with Maven wrapper...'",
      "chmod +x ./mvnw || (echo 'mvnw permission issue' && exit 2)",
      "./mvnw clean package -DskipTests || (echo 'Maven build failed' && exit 2)",

      "echo 'Running app with nohup...'",
      "JAR=$(find target -name '*.jar' | head -n 1) || (echo 'JAR not found' && exit 2)",
      "nohup java -jar $JAR > app.log 2>&1 &",

      "echo 'Provisioning complete.'"
    ]
  }
}
