output "instance_id" {
  value = aws_instance.web.id
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}

output "data_bucket" {
  value = aws_s3_bucket.data.bucket
}

output "log_group" {
  value = aws_cloudwatch_log_group.app.name
}
