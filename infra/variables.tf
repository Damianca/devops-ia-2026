variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  description = "Prefijo obligatorio de nombres"
  type        = string
  default     = "DevOPS_Clase11"
}

variable "environment" {
  description = "Experimento B: dev -> qa"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "Experimento A: t3.micro -> t3.small"
  type        = string
  default     = "t3.small"
}

variable "bucket_name" {
  description = "Bucket de datos, unico global (S3 no admite mayusculas ni '_')"
  type        = string

  validation {
    condition     = can(regex("^devops-clase11-[a-z0-9-]{3,48}$", var.bucket_name))
    error_message = "Debe empezar con 'devops-clase11-' y usar solo minusculas, numeros y '-'."
  }
}

variable "http_cidr" {
  type        = string
  description = "CIDR permitido a HTTP; usar TU_IP/32"

  validation {
    condition     = can(cidrhost(var.http_cidr, 0)) && endswith(var.http_cidr, "/32")
    error_message = "Usar una IP /32, por ejemplo 181.10.20.30/32."
  }
}

variable "log_retention_days" {
  description = "Experimento C: 7 -> 14"
  type        = number
  default     = 7
}
