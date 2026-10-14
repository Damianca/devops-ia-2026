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

# Restringí SSH a tu IP, por ejemplo "190.x.x.x/32". Por defecto queda abierto.
variable "ssh_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

# 1. Sufijo aleatorio para que el nombre del S3 sea globalmente único
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 2. Bucket S3
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

# Acceso público de lectura (para que la EC2 descargue el archivo por HTTP)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.web_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket     = aws_s3_bucket.web_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.web_bucket.arn}/*"
      }
    ]
  })
}

# 3. Subir index.html local al bucket
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  etag         = filemd5("${path.module}/index.html")
  content_type = "text/html"
}

# 4. Security Group
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

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
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

# 5. Instancia EC2 que descarga el HTML desde S3 y arranca Nginx
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # Esperar a que el archivo y la política pública existan antes de arrancar
  depends_on = [
    aws_s3_object.index_html,
    aws_s3_bucket_policy.public_read_policy,
  ]

  user_data_replace_on_change = false
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx curl
    systemctl enable --now nginx

    URL="https://${aws_s3_bucket.web_bucket.bucket_regional_domain_name}/index.html"
    curl -fsSL -o /var/www/html/index.html "$URL"
    echo "* * * * * root curl -fsSL -o /var/www/html/index.html $URL" > /etc/cron.d/sync-web
  EOF

  lifecycle {
    ignore_changes = [user_data]
  }

  tags = {
    Name = "WebServer-S3-EC2"
  }
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.web_bucket.id
  description = "Nombre del bucket S3 creado"
}

output "instance_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "IP publica de la instancia EC2 para ver la web"
}
