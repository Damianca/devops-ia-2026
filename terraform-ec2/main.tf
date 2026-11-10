terraform {
  required_version = ">= 1.0.0"
  backend "s3" {
    bucket = "taller-devops-state-hernandez"
    key    = "ec2/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "mi_servidor_terraform" {
  ami           = "ami-06b21ccaeff8cd686"
  instance_type = "t3.micro"

  tags = {
    Name = "Instancia-Desde-Terraform"
  }
}

output "instance_id" {
  value = aws_instance.mi_servidor_terraform.id
}

output "public_ip" {
  value = aws_instance.mi_servidor_terraform.public_ip
}
