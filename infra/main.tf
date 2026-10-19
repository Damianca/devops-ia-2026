data "aws_ssm_parameter" "al2023" { name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64" }
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  name = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_security_group" "web" {
  name_prefix = "${local.name}-web-"
  description = "HTTP limitado al CIDR del laboratorio"
  vpc_id = data.aws_vpc.default.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.http_cidr]
  }  tags = merge(local.tags, { Name = "${local.name}-sg" })
0}
resource "aws_instance" "web" {
  ami = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type
  subnet_id = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  associate_public_ip_address = true
  metadata_options { http_tokens = "required" }
  root_block_device { encrypted = true; volume_size = 8; volume_type = "gp3" }
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    echo '<h1>Infraestructura como codigo - ${local.name}</h1><p>Desplegado con Terraform y GitHub Actions</p>' > /usr/share/nginx/html/index.html
    systemctl enable --now nginx
  EOF
  tags = merge(local.tags, { Name = "${local.name}-web" })
}
resource "aws_s3_bucket" "files" { bucket = var.bucket_name; tags = merge(local.tags, { Name = "${local.name}-files" }) }
resource "aws_s3_bucket_public_access_block" "files" {
 bucket = aws_s3_bucket.files.id
 block_public_acls = true; block_public_policy = true; ignore_public_acls = true; restrict_public_buckets = true
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
 versioning_configuration { status = "Enabled" }
}
resource "aws_cloudwatch_log_group" "app" {
 name = "/lab/${local.name}/app"
 retention_in_days = var.log_retention_days
 tags = local.tags
}
