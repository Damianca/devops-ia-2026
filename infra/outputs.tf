output "web_url" { value = "http://${aws_instance.web.public_ip}" }
output "ec2_id" { value = aws_instance.web.id }
output "s3_bucket" { value = aws_s3_bucket.files.bucket }
output "cloudwatch_log_group" { value = aws_cloudwatch_log_group.app.name }
