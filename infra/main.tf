data "aws_caller_identity" "current" {}

# VPC y subredes por defecto de la cuenta (laboratorio)
data "aws_vpc" "default" {
  default = true
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
  # Fijamos AZ: no todas las AZ de us-east-1 ofrecen t3.micro (ej. us-east-1e)
  filter {
    name   = "availability-zone"
    values = [var.availability_zone]
  }
}

# AMI más reciente de Amazon Linux 2023 (trae el agente SSM y la AWS CLI)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  name = "${var.project}-web"
}

# --------------------------------------------------------- Bucket de artefactos
# El pipeline sube aquí el .tar.gz del sitio; la EC2 lo descarga vía SSM.
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${local.name}-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # destroy lo vacía y elimina
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    id     = "expire-old-releases"
    status = "Enabled"
    filter {
      prefix = "releases/"
    }
    expiration {
      days = 14
    }
  }
}

# --------------------------------------------------------------- Red / SG
# Solo HTTP entrante. Sin SSH: la administración se hace por SSM.
resource "aws_security_group" "web" {
  name        = "${local.name}-sg"
  description = "HTTP para Nginx (sin SSH, acceso por SSM)"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP"
  cidr_ipv4         = var.allowed_http_cidr
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "Salida para paquetes, SSM y S3"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# --------------------------------------------------------- IAM de la instancia
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project}-ec2-web-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "read_artifacts" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.artifacts.arn}/releases/*"]
  }
}

resource "aws_iam_role_policy" "read_artifacts" {
  name   = "read-artifacts"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.read_artifacts.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-ec2-web-profile"
  role = aws_iam_role.ec2.name
}

# ----------------------------------------------------------------- Instancia
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.al2023.insecure_value
  instance_type               = var.instance_type
  subnet_id                   = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_tokens   = "required" # IMDSv2
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  # La AMI "latest" cambia seguido: no recrear la instancia en cada apply.
  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = local.name
  }
}
