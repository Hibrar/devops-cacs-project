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

      # Wait for yum lock to be released (retry for up to 5 minutes)
      "echo 'Waiting for yum lock to be released...'",
      "for i in {1..30}; do sudo lsof /var/run/yum.pid || break; echo 'Yum is locked, retrying in 10s...'; sleep 10; done",

      # System update
      "echo 'Updating system...'",
      "sudo yum update -y",

      # Install Java 21
      "echo 'Installing Java 21...'",
      "sudo yum install -y java-21-amazon-corretto",

      # Verify Java
      "java -version || (echo 'Java install failed' && exit 2)",

      # Install Maven and Git
      "echo 'Installing Maven and Git...'",
      "sudo yum install -y maven git",

      # Clone the repo
      "echo 'Cloning GitHub repo...'",
      "git clone https://github.com/nldblanch/cacs-checklist.git /home/ec2-user/app",

      # Build the Spring Boot app
      "cd /home/ec2-user/app",
      "chmod +x mvnw",
      "./mvnw clean package -DskipTests || (echo 'Build failed' && exit 2)",

      # Find and run the JAR
      "JAR=$(find target -name '*.jar' | head -n 1)",
      "echo 'Running: $JAR'",
      "nohup java -jar $JAR > app.log 2>&1 &"
    ]
  }
}
