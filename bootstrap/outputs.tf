output "aws_role_arn" {
  description = "Cargar como variable de repositorio SANTALUCIA_AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "tf_state_bucket" {
  description = "Cargar como variable de repositorio SANTALUCIA_STATE_BUCKET"
  value       = aws_s3_bucket.tfstate.bucket
}
