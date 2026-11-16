output "web_url" { value = "http://${aws_instance.web.public_ip}" }
output "ec2_id" { value = aws_instance.web.id }
output "ec2_name" { value = aws_instance.web.tags["Name"] }
output "instance_type" { value = aws_instance.web.instance_type }
output "security_group" { value = aws_security_group.web.name }
output "s3_bucket" { value = aws_s3_bucket.files.bucket }
output "cloudwatch_log_group" { value = aws_cloudwatch_log_group.app.name }
