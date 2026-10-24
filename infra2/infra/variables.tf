variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "lab-iac"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "bucket_name" {
  description = "Nombre globalmente unico del bucket del lab (LAB_BUCKET_NAME)"
  type        = string
}

variable "http_cidr" {
  description = "CIDR autorizado al puerto 80, ej. 1.2.3.4/32 (LAB_HTTP_CIDR)"
  type        = string

  validation {
    condition     = can(cidrhost(var.http_cidr, 0))
    error_message = "http_cidr debe ser un CIDR valido, por ejemplo 203.0.113.10/32."
  }
}
