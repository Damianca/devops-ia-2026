terraform {
  backend "s3" {
    bucket = "terraform-state-rosales"
    key    = "lab/terraform.tfstate"
    region = "us-east-1"
  }
}
