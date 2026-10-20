terraform {
  required_version = ">= 1.10.0"

  # El nombre del bucket se pasa desde el workflow con -backend-config
  backend "s3" {
    key          = "pipelineThiago/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Sufijo aleatorio para que el nombre del bucket sea globalmente único
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 2. Bucket PRIVADO donde el pipeline deja los artefactos (releases/<sha>/index.html).
#    La EC2 los descarga con su rol IAM; ya no hace falta acceso público.
resource "aws_s3_bucket" "web_bucket" {
  bucket        = "mi-web-static-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.web_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.web_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Rol IAM para la EC2: SSM (para recibir comandos) + lectura de los artefactos
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_ssm" {
  name               = "web-server-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "artifact_read" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.web_bucket.arn}/releases/*"]
  }
}

resource "aws_iam_role_policy" "artifact_read" {
  name   = "read-release-artifacts"
  role   = aws_iam_role.ec2_ssm.id
  policy = data.aws_iam_policy_document.artifact_read.json
}

resource "aws_iam_instance_profile" "web" {
  name = "web-server-profile"
  role = aws_iam_role.ec2_ssm.name
}

# 4. Security Group: solo HTTP (el acceso de administración es por SSM, sin SSH)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Permitir trafico HTTP y SSH"

  ingress {
    description = "HTTP"
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

# AMI de Ubuntu 22.04 buscada dinámicamente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 5. Instancia EC2 con Nginx. El HTML NO lo maneja Terraform: lo publica el pipeline por SSM,
#    así que cambiar el HTML nunca reemplaza la instancia ni cambia la IP.
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.web.name
  associate_public_ip_address = true

  user_data_replace_on_change = false

  # Solo instala lo necesario; el contenido llega por SSM
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx curl awscli
    systemctl enable --now nginx
  EOF

  # Evita reemplazos accidentales (nueva AMI de Ubuntu o cambios en el script de arranque)
  lifecycle {
    ignore_changes = [ami, user_data]
  }

  tags = {
    Name = "WebServer-S3-EC2"
  }
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.web_bucket.id
  description = "Bucket privado donde se guardan los artefactos"
}

output "instance_id" {
  value       = aws_instance.web_server.id
  description = "ID de la instancia EC2 (destino de los comandos SSM)"
}

output "instance_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "IP publica de la instancia EC2 para ver la web"
}
