variable "aws_region" {
  description = "Región de AWS del laboratorio"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefijo de nombres (minúsculas, sin espacios). Debe coincidir con var.project de infra/"
  type        = string
  default     = "santalucia"
}

variable "owner" {
  description = "Tag Owner"
  type        = string
  default     = "pablo-santalucia"
}

variable "github_subject" {
  description = "Valor exacto de 'sub' que imprime el workflow 'OIDC - ver subject' en develop_santalucia"
  type        = string

  validation {
    condition     = endswith(var.github_subject, ":ref:refs/heads/develop_santalucia")
    error_message = "El subject debe corresponder a la rama develop_santalucia."
  }
}

variable "create_oidc_provider" {
  description = "false si la cuenta ya tiene el proveedor OIDC token.actions.githubusercontent.com"
  type        = bool
  default     = true
}
