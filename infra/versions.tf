terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Backend parcial: bucket, key y región se pasan con -backend-config
  # desde el workflow, así no queda nada específico de la cuenta en Git.
  # use_lockfile = lock nativo de S3 (Terraform >= 1.10), sin DynamoDB.
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project
      Owner     = var.owner
      ManagedBy = "terraform"
      Lab       = "pipeline-cicd-ec2"
    }
  }
}
