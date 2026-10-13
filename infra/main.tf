terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State remoto en el bucket creado por el bootstrap
  backend "s3" {
    bucket       = "tfstate-posse-cicd-2026"
    key          = "cicd/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  nombre = "cicd-posse"
}

data "aws_caller_identity" "actual" {}

# AMI más reciente de Amazon Linux 2023
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------- Bucket de artefactos ----------

resource "aws_s3_bucket" "artefactos" {
  bucket        = "${local.nombre}-artefactos-${data.aws_caller_identity.actual.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "artefactos" {
  bucket                  = aws_s3_bucket.artefactos.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- Rol IAM de la EC2 ----------

resource "aws_iam_role" "ec2" {
  name = "${local.nombre}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Permite que la EC2 reciba comandos por SSM
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Permite que la EC2 lea el bucket de artefactos
resource "aws_iam_role_policy" "leer_artefactos" {
  name = "leer-artefactos"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.artefactos.arn}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.nombre}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ---------- Security group ----------

resource "aws_security_group" "web" {
  name        = "${local.nombre}-web"
  description = "Permite HTTP entrante"

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

# ---------- Instancia EC2 ----------

resource "aws_instance" "web" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  vpc_security_group_ids = [aws_security_group.web.id]

  # Se ejecuta una sola vez, al arrancar la instancia
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable --now nginx
  EOF

  tags = {
    Name = "${local.nombre}-web"
  }
}

# ---------- Outputs ----------

output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "artefactos_bucket" {
  value = aws_s3_bucket.artefactos.bucket
}

output "url" {
  value = "http://${aws_instance.web.public_ip}"
}
