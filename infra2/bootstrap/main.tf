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
  region = var.region
}

# ---------- Bucket de estado de Terraform ----------
resource "aws_s3_bucket" "state" {
  bucket        = var.state_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ---------- OIDC GitHub -> AWS ----------
data "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "trust" {
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
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:*${var.github_repo}*:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "github" {
  name               = "lab-iac-github-actions"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# Permisos de DEMO (amplios por servicio). Reducir en producción.
data "aws_iam_policy_document" "perms" {
  statement {
    sid       = "LabServices"
    actions   = ["ec2:*", "s3:*", "logs:*"]
    resources = ["*"]
  }
  statement {
    sid       = "SsmAmi"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:*:*:parameter/aws/service/ami-amazon-linux-latest/*"]
  }
}

resource "aws_iam_role_policy" "github" {
  name   = "lab-iac-permissions"
  role   = aws_iam_role.github.id
  policy = data.aws_iam_policy_document.perms.json
}
