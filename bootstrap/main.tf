###############################################################################
# BOOTSTRAP - DevOPS_Clase11 (rama develop_20oct26_santalucia)
# Se ejecuta UNA vez en la VM con el usuario IAM IaC_Terraform.
# Crea: bucket de estado + IAM Role para GitHub Actions (OIDC).
# El estado del bootstrap queda LOCAL: guardarlo y NO subirlo al repo.
###############################################################################

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

  default_tags {
    tags = {
      Project   = var.project
      Owner     = "pablo-santalucia"
      Component = "bootstrap"
      ManagedBy = "Terraform"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  description = "Prefijo obligatorio de nombres"
  type        = string
  default     = "DevOPS_Clase11"
}

variable "state_bucket" {
  description = "Bucket del estado remoto (S3: solo minusculas, numeros y '-')"
  type        = string

  validation {
    condition     = can(regex("^devops-clase11-[a-z0-9-]{3,48}$", var.state_bucket))
    error_message = "Debe empezar con 'devops-clase11-' y usar solo minusculas, numeros y '-'."
  }
}

variable "github_subject" {
  description = "Claim 'sub' exacto del token OIDC (este repo usa IDs de owner y repo)"
  type        = string
  default     = "repo:Damianca@2234442/devops-ia-2026@1317392920:ref:refs/heads/develop_20oct26_santalucia"

  validation {
    condition     = endswith(var.github_subject, ":ref:refs/heads/develop_20oct26_santalucia")
    error_message = "El subject debe corresponder a la rama develop_20oct26_santalucia."
  }
}

variable "create_oidc_provider" {
  description = "false si la cuenta YA tiene el proveedor OIDC de GitHub (ej. creado en develop_santalucia)"
  type        = bool
  default     = false
}

locals {
  oidc_url = "https://token.actions.githubusercontent.com"
  oidc_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# --------------------------------------------------------- Bucket de estado
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket

  tags = {
    Name    = "${var.project}-tfstate"
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

# ------------------------------------------------------------ Proveedor OIDC
# Solo puede existir UNO por cuenta: por defecto se reutiliza el existente.
resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_oidc_provider ? 1 : 0
  url            = local.oidc_url
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = local.oidc_url
}

# ------------------------------------------------- Rol para GitHub Actions
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Solo mi rama puede asumir el rol
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_subject]
    }
  }
}

resource "aws_iam_role" "github" {
  name               = "${var.project}-github-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = {
    Name = "${var.project}-github-role"
  }
}

# Permisos de laboratorio (amplios en EC2/Logs; reducir en produccion)
resource "aws_iam_role_policy" "lab" {
  name = "${var.project}-lab-policy"
  role = aws_iam_role.github.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:*", "logs:*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:${var.aws_region}::parameter/aws/service/*"
      },
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*",
          "arn:aws:s3:::devops-clase11-*",
          "arn:aws:s3:::devops-clase11-*/*"
        ]
      }
    ]
  })
}

output "role_arn" {
  description = "-> variable de GitHub SANTALUCIA_CLASE11_ROLE_ARN"
  value       = aws_iam_role.github.arn
}

output "state_bucket" {
  description = "-> variable de GitHub SANTALUCIA_CLASE11_STATE_BUCKET"
  value       = aws_s3_bucket.state.id
}
