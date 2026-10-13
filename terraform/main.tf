terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "taller-devops-tfstate-fernando"
    key    = "cicd-lab/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

# AMI más reciente de Amazon Linux 2023 (x86_64)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Rol para que la EC2 pueda recibir comandos por SSM
resource "aws_iam_role" "ec2_ssm" {
  name = "cicd-lab-ec2-ssm-vagogrecco"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Permiso para que la EC2 descargue el artefacto desde el bucket
resource "aws_iam_role_policy" "ec2_s3_read" {
  name = "leer-artefacto"
  role = aws_iam_role.ec2_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "arn:aws:s3:::taller-devops-tfstate-fernando/cicd-lab-artifacts/*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "cicd-lab-ec2-profile-vagogrecco"
  role = aws_iam_role.ec2_ssm.name
}

# Security group: solo HTTP (sin SSH, usamos SSM)
resource "aws_security_group" "web" {
  name        = "cicd-lab-web-vagogrecco"
  description = "HTTP para el laboratorio CI/CD"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# La instancia EC2 con Nginx
resource "aws_instance" "web" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable --now nginx
  EOF

  tags = {
    Name = "cicd-lab-vagogrecco"
  }
}
