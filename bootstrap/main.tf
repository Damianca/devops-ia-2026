# -----------------------------------------------------------------------------
# BOOTSTRAP — se ejecuta UNA sola vez, en local, con credenciales de admin.
# Crea lo que el pipeline necesita para existir y que NO se borra con destroy:
#   - Bucket S3 para el state remoto de Terraform (con versionado y lock nativo)
#   - Proveedor OIDC de GitHub (opcional, puede existir ya en la cuenta)
#   - Rol IAM que GitHub Actions asume vía OIDC (sin access keys)
# Su propio state queda LOCAL (bootstrap/terraform.tfstate, ignorado por Git).
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project
      Owner     = var.owner
      ManagedBy = "terraform-bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  state_bucket = "${var.project}-tfstate-${local.account_id}"
  oidc_url     = "https://token.actions.githubusercontent.com"
  oidc_arn     = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# ---------------------------------------------------------------- State bucket
resource "aws_s3_bucket" "tfstate" {
  bucket = local.state_bucket

  # Protege el state ante un borrado accidental.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------------------- OIDC provider
# Solo puede existir UNO por cuenta. Si ya lo creó otro alumno/curso,
# usar create_oidc_provider = false y se reutiliza el existente.
resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_oidc_provider ? 1 : 0
  url            = local.oidc_url
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = local.oidc_url
}

# ------------------------------------------------------------ Rol para Actions
data "aws_iam_policy_document" "trust" {
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

    # Solo la rama develop_santalucia puede asumir el rol. El repo del curso
    # usa un subject personalizado (incluye IDs), por eso se pasa el valor
    # exacto obtenido con el workflow "OIDC - ver subject".
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_subject]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = "${var.project}-github-actions"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "pipeline" {
  # State remoto (incluye el archivo .tflock del lock nativo de S3)
  statement {
    sid       = "StateBucketList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]
  }
  statement {
    sid       = "StateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/*"]
  }

  # Bucket de artefactos web que crea la infra (prefijo del proyecto)
  statement {
    sid       = "ArtifactBuckets"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.project}-web-*", "arn:aws:s3:::${var.project}-web-*/*"]
  }

  # EC2: instancia, security group, consultas de VPC/AMI
  statement {
    sid       = "EC2"
    actions   = ["ec2:*"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # IAM: solo roles/instance profiles con el prefijo del proyecto
  statement {
    sid = "IAMScoped"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:TagRole", "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy", "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy",
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile",
      "iam:TagInstanceProfile", "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
      "iam:ListInstanceProfilesForRole", "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.project}-ec2-*",
      "arn:aws:iam::${local.account_id}:instance-profile/${var.project}-ec2-*"
    ]
  }

  # SSM: AMI pública (parámetro) + Run Command para desplegar
  statement {
    sid = "SSM"
    actions = [
      "ssm:GetParameter", "ssm:GetParameters",
      "ssm:SendCommand", "ssm:GetCommandInvocation", "ssm:ListCommandInvocations",
      "ssm:DescribeInstanceInformation"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "pipeline" {
  name   = "${var.project}-pipeline"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.pipeline.json
}
