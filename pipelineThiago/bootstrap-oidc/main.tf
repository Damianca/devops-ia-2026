# Se ejecuta UNA SOLA VEZ, a mano (no desde el pipeline), con credenciales de administrador:
#   cd pipelineThiago/bootstrap-oidc
#   terraform init
#   terraform apply
# Crea el proveedor OIDC de GitHub y el rol que asume el pipeline.
# Guardá el output role_arn en el secret AWS_ROLE_ARN del repositorio.
# No borres el state local (terraform.tfstate) de esta carpeta si querés poder modificarlo después.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "github_repo" {
  type        = string
  description = "Repositorio en formato owner/repo"
  default     = "Damianca/devops-ia-2026"
}

variable "branch" {
  type        = string
  description = "Única rama autorizada a asumir el rol"
  default     = "develop_TAVELLA"
}

# Poné false si tu cuenta ya tiene el proveedor OIDC de GitHub (AWS solo permite uno por URL)
variable "create_oidc_provider" {
  type    = bool
  default = true
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

data "aws_iam_openid_connect_provider" "existing" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.existing[0].arn
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Solo este repo y solo esta rama pueden asumir el rol
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.branch}"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-terraform-deploy"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# Para un trabajo práctico alcanza con AdministratorAccess (el rol solo lo asume tu rama).
# En un proyecto real conviene reemplazarlo por una política con los permisos mínimos.
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Guardalo en el secret AWS_ROLE_ARN del repositorio"
}
