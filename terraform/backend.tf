terraform {
  required_version = ">= 1.10" # 1.10+ permite locking nativo en S3 (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # El bucket se pasa en el init (-backend-config) para no hardcodearlo
    key          = "lab-cicd/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # evita que dos ejecuciones modifiquen el state a la vez
  }
}
