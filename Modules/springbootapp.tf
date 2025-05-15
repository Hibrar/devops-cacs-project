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

        "sudo systemctl stop dnf-automatic.timer || true",
        "sudo systemctl disable dnf-automatic.timer || true",

        "echo 'Checking for DNF lock...'",
        "for i in {1..60}; do",
        "  sudo lsof /var/cache/dnf/lock >/dev/null 2>&1 || break",
        "  echo 'Waiting for dnf lock...'; sleep 5",
        "done",

        "sudo dnf makecache --refresh -y",
        "sudo dnf install -y java-21-amazon-corretto maven git",

        "git clone https://github.com/nldblanch/cacs-checklist.git /home/ec2-user/app",
        "cd /home/ec2-user/app",
        "chmod +x ./mvnw",
        "./mvnw clean package -DskipTests",

        "cd /home/ec2-user/app",
        "JAR=$(find target -name '*.jar')",
        "SPRING_APPLICATION_NAME=cacs-checklist \\",
        "SPRING_DATA_MONGODB_HOST=172.31.45.143 \\",
        "SPRING_DATA_MONGODB_PORT=27017 \\",
        "SPRING_DATA_MONGODB_DATABASE=cacs \\",
        "SPRING_DATA_MONGODB_URI=mongodb://172.31.45.143:27017/cacs \\",
        "SERVER_PORT=8080 \\",
        "SPRING_JPA_HIBERNATE_DDL_AUTO=none \\",
        "SPRING_JPA_SHOW_SQL=false \\",
        "SPRING_JPA_HIBERNATE_NAMING_IMPLICIT_STRATEGY=org.hibernate.boot.model.naming.ImplicitNamingStrategyJpaCompliantImpl \\",
        "SPRING_JPA_HIBERNATE_NAMING_PHYSICAL_STRATEGY=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl \\",
        "SPRING_AUTOCONFIGURE_EXCLUDE=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration \\",
        "nohup java -jar $JAR > app.log 2>&1 &"
      ]
    }

}
