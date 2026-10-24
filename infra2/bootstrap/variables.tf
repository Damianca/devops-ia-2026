variable "region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  description = "Bucket S3 para el estado de Terraform (nombre globalmente unico)"
  type        = string
}

variable "github_repo" {
  description = "Repo en formato owner/repo"
  type        = string
  default     = "Damianca/devops-ia-2026"
}

variable "github_branch" {
  description = "Rama autorizada a asumir el rol"
  type        = string
  default     = "develop_Tavella_2"
}
