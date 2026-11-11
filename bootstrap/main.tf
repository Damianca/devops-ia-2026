
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "state_bucket" {
  type = string
}

variable "github_subject" {
  type        = string
  description = "sub exacto del token OIDC de GitHub para la rama del laboratorio"
}

# Bucket S3 para el estado de Terraform
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket

  tags = {
    Project = "clase-iac"
    Purpose = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Proveedor OIDC para GitHub Actions
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Politica de confianza del rol IAM
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [var.github_subject]
    }
  }
}

resource "aws_iam_role" "github" {
  name               = "lab-iac-galleguillo-github"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

# Permisos para el laboratorio
resource "aws_iam_role_policy" "lab" {
  name = "lab-iac-galleguillo-policy"
  role = aws_iam_role.github.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:*", "logs:*", "ssm:GetParameter"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*",
          "arn:aws:s3:::lab-iac-*",
          "arn:aws:s3:::lab-iac-*/*"
        ]
      }
    ]
  })
}

output "role_arn" {
  value = aws_iam_role.github.arn
}

output "state_bucket" {
  value = aws_s3_bucket.state.id
}
