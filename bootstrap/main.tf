terraform {
  required_version = ">= 1.6.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.aws_region }
variable "aws_region" { default = "us-east-1" }
variable "github_owner" { type = string }
variable "github_repo" { type = string }
variable "state_bucket" { type = string }
resource "aws_s3_bucket" "state" { bucket = var.state_bucket
  tags = { Project = "clase-iac", Purpose = "terraform-state" }
}
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals { type = "Federated"; identifiers = [aws_iam_openid_connect_provider.github.arn] }
    condition { test = "StringEquals"; variable = "token.actions.githubusercontent.com:aud"; values = ["sts.amazonaws.com"] }
    condition { test = "StringEquals"; variable = "token.actions.githubusercontent.com:sub"; values = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/develop_20oct26"] }
  }
}
resource "aws_iam_role" "github" {
  name = "lab-iac-github-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}
resource "aws_iam_role_policy" "lab" {
  name = "lab-iac-policy"
  role = aws_iam_role.github.id
  # Permisos amplios SOLO para laboratorio; limitar recursos/acciones en producción.
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Effect = "Allow", Action = ["ec2:*", "logs:*"], Resource = "*" },
    { Effect = "Allow", Action = ["s3:*"], Resource = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*", "arn:aws:s3:::lab-iac-*", "arn:aws:s3:::lab-iac-*/*"] }
  ] })
}
output "role_arn" { value = aws_iam_role.github.arn }
output "state_bucket" { value = aws_s3_bucket.state.id }
