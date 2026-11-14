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
  default = "t3.small"
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "bucket_name" {
  type        = string
  description = "Bucket de datos (nombre global unico)"
}

variable "http_cidr" {
  type        = string
  description = "Origen permitido en el puerto 80"

  validation {
    condition     = can(cidrhost(var.http_cidr, 0)) && endswith(var.http_cidr, "/32")
    error_message = "http_cidr debe ser una sola IPv4 en formato x.x.x.x/32."
  }
}
