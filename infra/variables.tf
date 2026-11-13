variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefijo de nombres. Debe coincidir con el usado en bootstrap/"
  type        = string
  default     = "santalucia"
}

variable "owner" {
  description = "Tag Owner"
  type        = string
  default     = "pablo-santalucia"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "allowed_http_cidr" {
  description = "CIDR con acceso HTTP a la web"
  type        = string
  default     = "0.0.0.0/0"
}

variable "availability_zone" {
  description = "AZ de la subred por defecto donde se lanza la EC2"
  type        = string
  default     = "us-east-1a"
}
