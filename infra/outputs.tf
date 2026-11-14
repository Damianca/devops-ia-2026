output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}

output "instance_id" {
  value = aws_instance.web.id
}

output "data_bucket" {
  value = aws_s3_bucket.data.id
}

output "log_group" {
  value = aws_cloudwatch_log_group.app.name
}
# exp4: nuevo nombre de bucket
