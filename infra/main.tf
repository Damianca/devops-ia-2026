###############################################################################
# INFRA - DevOPS_Clase11: EC2 + Nginx + SG, S3 privado, CloudWatch Log Group
###############################################################################

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_vpc" "default" {
  default = true
}

# AZs que ofrecen el tipo de instancia (us-east-1e no tiene t3)
data "aws_ec2_instance_type_offerings" "available" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_ec2_instance_type_offerings.available.locations
  }
}

locals {
  name = "${var.project}-${var.environment}" # DevOPS_Clase11-dev

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "pablo-santalucia"
    ManagedBy   = "Terraform"
  }
}

# ------------------------------------------------------------ Security Group
resource "aws_security_group" "web" {
  name_prefix = "${local.name}-web-sg-"
  description = "HTTP limitado al CIDR del laboratorio"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP desde mi IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-web-sg"
  })

  # Experimento B: al cambiar el nombre, crear la SG nueva ANTES de borrar
  # la vieja (si no, AWS no la deja borrar porque la EC2 la esta usando)
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------- EC2 Amazon Linux 2023 + Nginx
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required" # IMDSv2 obligatorio
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    echo '<h1>${local.name}</h1><p>Infraestructura como codigo - Terraform + GitHub Actions</p>' > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF

  # Una AMI nueva publicada en SSM no debe forzar reemplazo en cada plan
  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-web"
  })
}

# ------------------------------------------------------------ S3 privado
resource "aws_s3_bucket" "files" {
  bucket = var.bucket_name

  tags = merge(local.tags, {
    Name = "${local.name}-files"
  })
}

resource "aws_s3_bucket_public_access_block" "files" {
  bucket = aws_s3_bucket.files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "files" {
  bucket = aws_s3_bucket.files.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------ CloudWatch Logs
resource "aws_cloudwatch_log_group" "app" {
  name              = "${var.project}/${var.environment}/app" # DevOPS_Clase11/dev/app
  retention_in_days = var.log_retention_days

  tags = merge(local.tags, {
    Name = "${local.name}-app-logs"
  })
}
