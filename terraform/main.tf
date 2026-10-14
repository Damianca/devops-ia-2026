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

resource "aws_instance" "web" {
  ami           = "ami-0b245cc5f82576748"
  instance_type = "t3.micro"

  tags = {
    Name = "EC2-Desde-Terraform"
  }
}
