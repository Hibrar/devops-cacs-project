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

      # Update system packages
      "sudo yum update -y",

      # Install Java 17 (recommended for Spring Boot unless your app uses Java 21)
      "sudo yum install -y java-17-amazon-corretto",
      "java -version",

      # Install Maven and Git
      "sudo yum install -y maven git",

      # Clone the Spring Boot project
      "git clone https://github.com/nldblanch/cacs-checklist.git springboot-app",

      # Navigate into backend and build the application
      "cd springboot-app/backend",
      "mvn clean package -DskipTests",

      # Run the Spring Boot application (adjust JAR name based on actual output)
      "nohup java -jar target/cacs-checklist-0.0.1-SNAPSHOT.jar > output.log 2>&1 &",

      # Optional: wait and tail the output
      "sleep 10",
      "tail -n 30 output.log"
    ]
  }
}
