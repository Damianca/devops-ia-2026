output "role_arn" {
  description = "Copiar a Secret AWS_ROLE_ARN"
  value       = aws_iam_role.github.arn
}

output "state_bucket" {
  description = "Copiar a Secret TF_STATE_BUCKET"
  value       = aws_s3_bucket.state.bucket
}
