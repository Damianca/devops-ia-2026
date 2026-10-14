terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Asegúrate de que coincida con tu región configurada
}

resource "aws_instance" "mi_ec2_terraform" {
  ami           = "ami-0b245cc5f82576748" # Amazon Linux (ajusta si usas otra región)
  instance_type = "t3.micro"

  tags = {
    Name = "EC2-Desde-Terraform"
  }
}
