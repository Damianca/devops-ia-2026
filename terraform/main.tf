terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Creamos un Security Group dedicado que abre el puerto 80 (HTTP) y el 22 (SSH)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Permitir trafico HTTP y SSH para el laboratorio"

  # Regla de entrada para HTTP (Puerto 80) desde cualquier IP de Internet
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de entrada para SSH (Puerto 22) para acceso remoto opcional
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir todo el tráfico saliente desde la instancia
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Terraform-Web-SG"
  }
}

# 2. Asociamos el Security Group recién creado a la instancia EC2
resource "aws_instance" "web" {
  ami                    = "ami-0b245cc5f82576748"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              cat << 'INJECTED_HTML' > /var/www/html/index.html
              ${file("${path.module}/../web/index.html")}
              INJECTED_HTML
              EOF

  tags = {
    Name = "EC2-Desde-Terraform"
  }
}
