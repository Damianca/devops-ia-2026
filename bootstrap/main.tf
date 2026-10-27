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

variable "state_bucket" {
  type = string
}

# Proveedor OIDC existente: no se crea otro.
data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::828035972737:oidc-provider/token.actions.githubusercontent.com"
}

# Confianza exclusiva para nuestra rama.
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
      values = [
        "repo:Damianca@2234442/devops-ia-2026@1317392920:ref:refs/heads/develop_20oct26_PERLO"
      ]
    }
  }
}

resource "aws_iam_role" "github" {
  name               = "lab-iac-perlo-20oct26-github"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "lab" {
  name = "lab-iac-perlo-20oct26-policy"
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
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = "arn:aws:s3:::${var.state_bucket}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::${var.state_bucket}/clase/perlo-20oct26/terraform.tfstate"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.state_bucket}/clase/perlo-20oct26/terraform.tfstate.tflock"
      },
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::lab-iac-perlo-*",
          "arn:aws:s3:::lab-iac-perlo-*/*"
        ]
      }
    ]
  })
}

output "role_arn" {
  value = aws_iam_role.github.arn
}

output "state_bucket" {
  value = var.state_bucket
}
