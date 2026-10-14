xprovider "aws" {
  region = var.region
}

# AMI (imagen del sistema) de Amazon Linux 2023 más reciente; ya trae el agente SSM y AWS CLI
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Usamos la VPC (red) y la subnet por defecto para simplificar el laboratorio
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = [var.az]
  }
}

# Firewall: solo HTTP (puerto 80). Sin SSH: administramos por SSM
resource "aws_security_group" "web" {
  name        = "${var.project}-web"
  description = "HTTP publico"
  vpc_id      = data.aws_vpc.default.id

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

# Rol de la EC2: permite que SSM la administre y que lea el artefacto de S3
resource "aws_iam_role" "ec2" {
  name = "${var.project}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "artifacts" {
  name = "read-artifacts"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "arn:aws:s3:::${var.artifacts_bucket}/artifacts/*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  # Corre una sola vez al primer arranque: instala Nginx y deja una página provisoria
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    echo "<h1>Servidor listo, esperando despliegue</h1>" > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF

  tags = {
    Name    = "${var.project}-web"
    Project = var.project
  }
}
