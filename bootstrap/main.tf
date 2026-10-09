terraform {
  required_version = ">= 1.10, < 2.0"
  required_providers {
    aws = {
       source = "hashicorp/aws"
       version = "~> 6.0"
    }
  }
}
variable "region" {
  type     = string
  default = "us-east-1"
}
variable "bucket_name" { type = string }
variable "github_subject" { type = string }
provider "aws" { region = var.region }
data "aws_caller_identity" "current" {}
locals {
  account = data.aws_caller_identity.current.account_id
  ec2_role = "arn:aws:iam::${local.account}:role/lab-web-ec2"
}
resource "aws_s3_bucket" "lab" {
  bucket         = var.bucket_name
  force_destroy = false
}
resource "aws_s3_bucket_versioning" "lab" {
  bucket = aws_s3_bucket.lab.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "lab" {
  bucket = aws_s3_bucket.lab.id
  rule {
    apply_server_side_encryption_by_default {
       sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "lab" {
  bucket                   = aws_s3_bucket.lab.id
  block_public_acls        = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets = true
}
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
resource "aws_iam_role" "github" {
  name = "lab-web-github"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
     Statement = [{
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = { StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = var.github_subject
        } }
     }]
  })
}
resource "aws_iam_role" "ec2" {
  name = "lab-web-ec2"
  assume_role_policy = jsonencode({
     Version = "2012-10-17"
     Statement = [{
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = { Service = "ec2.amazonaws.com" }
     }]
  })
}
resource "aws_iam_role_policy_attachment" "ssm" {
  role         = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "web" {
  name = "lab-web-ec2-profile"
  role = aws_iam_role.ec2.name
}
resource "aws_iam_role_policy" "read_app" {
  role = aws_iam_role.ec2.id
  policy = jsonencode({
     Version = "2012-10-17"
     Statement = [{
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.lab.arn}/artifacts/*"
     }]
  })
}
resource "aws_iam_role_policy" "pipeline" {
  role = aws_iam_role.github.id
  policy = jsonencode({
     Version = "2012-10-17"
     Statement = [
        {
          Effect   = "Allow"
          Action   = ["ec2:*"]
          Resource = "*"
          Condition = { StringEquals = {
            "aws:RequestedRegion" = var.region
          } }
       },
       {
          Effect = "Allow"
          Action = ["ssm:GetParameter", "ssm:SendCommand",
            "ssm:GetCommandInvocation", "ssm:DescribeInstanceInformation"]
          Resource = "*"
       },
       {
          Effect = "Allow"
          Action = ["s3:ListBucket"]
          Resource = aws_s3_bucket.lab.arn
       },
       {
          Effect = "Allow"
          Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          Resource = [
            "${aws_s3_bucket.lab.arn}/state/*",
            "${aws_s3_bucket.lab.arn}/artifacts/*"
          ]
       },
       {
          Effect = "Allow"
          Action = ["iam:GetInstanceProfile"]
          Resource = aws_iam_instance_profile.web.arn
       },
       {
          Effect = "Allow"
          Action = ["iam:PassRole"]
          Resource = local.ec2_role
          Condition = { StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          } }
       }
     ]
  })
}
output "github_role_arn" { value = aws_iam_role.github.arn }
output "bucket_name" { value = aws_s3_bucket.lab.id }

