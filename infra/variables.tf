variable "aws_region" {
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

variable "bucket_name" {
  type = string
}

variable "http_cidr" {
  type        = string
  description = "CIDR permitido a HTTP; usar TU_IP/32"
}

variable "log_retention_days" {
  type    = number
  default = 7
}
