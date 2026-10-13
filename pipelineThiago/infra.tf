terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 5.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 3.6.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

# 1. Generar un sufijo aleatorio para que el nombre del S3 sea globalmente único
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 2. Crear el Bucket S3
resource "aws_s3_bucket" "web_bucket" {
  bucket        = "mi-web-static-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# Permitir acceso público de lectura al bucket (necesario para que la EC2 descargue el archivo fácilmente por HTTP)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.web_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_acls    = false
}

resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.web_bucket.id

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

# 3. Subir tu archivo index.html local al Bucket S3
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  etag         = filemd5("${path.module}/index.html")
  content_type = "text/html"
}

# 4. Grupo de Seguridad para la EC2
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. Instancia EC2 (t3.micro) que descarga el HTML desde el S3 y arranca Nginx
resource "aws_instance" "web_server" {
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # Script que se ejecuta al iniciar la máquina
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx curl
              systemctl start nginx
              systemctl enable nginx
              
              # Descargar el index.html directamente desde S3 usando su URL pública
              curl -o /var/www/html/index.html https://${aws_s3_bucket.web_bucket.bucket_domain_name}/index.html
              EOF

  tags = {
    Name = "WebServer-S3-EC2"
  }
}

# Outputs para ver la información al terminar
output "s3_bucket_name" {
  value       = aws_s3_bucket.web_bucket.id
  description = "Nombre del bucket S3 creado"
}

output "instance_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "IP publica de la instancia EC2 para ver la web"
}
