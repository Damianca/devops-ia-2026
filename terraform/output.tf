output "public_ip" {
  description = "IP pública de la instancia"
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "URL de la página"
  value       = "http://${aws_instance.web.public_dns}"
}
