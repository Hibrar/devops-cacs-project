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
      "sudo yum update -y",

      # Install Java 21 (no need for openjdk11)
      "sudo yum clean metadata",
      "sudo yum install -y java-21-amazon-corretto",

      # Install Maven and Git
      "sudo yum install -y maven git",

      # Clone the Spring Boot GitHub repo
      "git clone https://github.com/nldblanch/cacs-checklist.git /home/ec2-user/app",
      "cd /home/ec2-user/app",

      # Build the Spring Boot application
      "./mvnw clean package -DskipTests",

      # Run the app (on port 8080 by default)
      "nohup java -jar target/*SNAPSHOT.jar > app.log 2>&1 &"
    ]
  }
}
