# ✅ EC2 Instance to run Spring Boot app
resource "aws_instance" "springboot_app" {
  ami                    = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  iam_instance_profile   = aws_iam_instance_profile.cacs_instance_profile.name

  tags = {
    Name = "springboot-app"
  }

  # ✅ SSH connection details
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.ssh_private_key
    host        = self.public_ip
  }

  # ✅ Commands to run on the EC2 instance
  provisioner "remote-exec" {
    inline = [
      "set -e",

      # Update system packages
      "sudo yum update -y",

      # Install Java 17
      "sudo yum install -y java-21-amazon-corretto",
      "java -version",

      # Install Maven
      "sudo yum install -y maven",

      # Install Git and clone your Spring Boot repository
      "sudo yum install -y git",
      "git clone https://github.com/nldblanch/cacs-checklist.git springboot-app",

      # Navigate to the backend folder and build the application
      "cd springboot-app/backend",
      "mvn clean package -DskipTests",

      # Run the Spring Boot application in the background
      "nohup java -jar target/*.jar > output.log 2>&1 &"
    ]
  }
}
