terraform {
  required_version = ">= 1.10, < 2.0"
  backend "s3" {
    key           = "state/lab-web/terraform.tfstate"
    encrypt       = true
    use_lockfile = true
  }
  required_providers {
    aws = {
       source = "hashicorp/aws"
       version = "~> 6.0"
    }
  }
}
variable "region" {
  type     = string
  default = "us-east-1"
}
provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = "lab-web", ManagedBy = "Terraform" }
  }
}
data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
data "aws_iam_instance_profile" "web" {
  name = "lab-web-ec2-profile"
}
resource "aws_vpc" "lab" {
  cidr_block             = "10.70.0.0/16"
  enable_dns_support     = true
  enable_dns_hostnames = true
  tags = { Name = "lab-web-vpc" }
}
resource "aws_subnet" "public" {
  vpc_id                    = aws_vpc.lab.id
  cidr_block                = "10.70.1.0/24"
  map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
}
resource "aws_route_table_association" "public" {
  subnet_id        = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
resource "aws_security_group" "web" {
  name    = "lab-web-http"
  vpc_id = aws_vpc.lab.id
  ingress {
    from_port     = 80
    to_port       = 80
    protocol      = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port     = 0
    to_port       = 0
    protocol      = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "web" {
  ami                               = data.aws_ssm_parameter.ami.value
  instance_type                     = "t3.micro"
  subnet_id                         = aws_subnet.public.id
  vpc_security_group_ids            = [aws_security_group.web.id]
  associate_public_ip_address = true
  iam_instance_profile              = data.aws_iam_instance_profile.web.name
  user_data                         = file("${path.module}/user-data.sh")
  user_data_replace_on_change = true
  metadata_options { http_tokens = "required" }
  root_block_device {
    volume_size                = 8
    volume_type                = "gp3"
    encrypted                  = true
    delete_on_termination = true
  }
  tags = { Name = "lab-web-ec2" }
  depends_on = [aws_route_table_association.public]
}
output "instance_id" { value = aws_instance.web.id }
output "web_url" { value = "http://${aws_instance.web.public_ip}" }

