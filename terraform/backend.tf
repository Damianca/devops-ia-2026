terraform {
  backend "s3" {
    bucket = "terraform-state-rosales-utn"
    key    = "lab/terraform.tfstate"
    region = "us-east-1"
  }
}
