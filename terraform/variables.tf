variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "lab-cicd"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "az" {
  type    = string
  default = "us-east-1a"
}

variable "artifacts_bucket" {
  type        = string
  description = "Bucket S3 donde el pipeline sube el artefacto (la EC2 lo lee)"
}
