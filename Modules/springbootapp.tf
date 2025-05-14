resource "aws_instance" "springboot_app" {
  ami                    = "ami-0faab6bdbac9486fb" # Ubuntu 22.04 LTS
  instance_type          = "t2.micro"
  key_name               = "terraform_access"
  vpc_security_group_ids = [aws_security_group.allow_tls.id] # Reuse existing SG
  iam_instance_profile   = aws_iam_instance_profile.cacs_instance_profile.name

  tags = {
    Name = "SpringBootApp"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = self.public_ip
    }

    inline = [
      "sudo apt update -y",
      "sudo apt install -y openjdk-17-jdk maven git",

      # Clone the repo
      "git clone https://github.com/nldblanch/cacs-checklist.git",

      # Go into the repo and build the app
      "cd cacs-checklist/backend/springboot && mvn clean package",

      # Run the jar file
      "nohup java -jar target/*.jar > app.log 2>&1 &"
    ]
  }
}
