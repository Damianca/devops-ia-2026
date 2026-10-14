
variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI compatible con Amazon Linux 2023 en la región elegida"
  type        = string
}

variable "ssh_cidr" {
  description = "IP pública autorizada para SSH en formato CIDR"
  type        = string
}
