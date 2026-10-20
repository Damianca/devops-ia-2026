# CI/CD en AWS

## Requisitos

- AWS CLI, Terraform `>= 1.10.0` y credenciales AWS.
- GitHub Actions secret `AWS_ROLE_ARN_TAVELLA` con el ARN del rol OIDC.

## Configurar OIDC (una vez)

Desde la raíz del repositorio, con credenciales AWS administrativas:

```bash
cd pipelineThiago/bootstrap-oidc
terraform init
terraform apply
terraform output -raw role_arn
```

Guarda el ARN como `AWS_ROLE_ARN_TAVELLA` en **GitHub → Settings → Secrets and variables → Actions**. Conserva el estado local de `bootstrap-oidc`.

## Desplegar

Haz `push` a `develop_TAVELLA`. El workflow **CD** valida, aplica Terraform, publica `index.html` en EC2 mediante S3/SSM y verifica HTTP.

## Destruir

Con credenciales AWS de la misma cuenta, desde la raíz del repo:

```bash
cd pipelineThiago
export AWS_REGION=us-east-1
TF_STATE_BUCKET="$(bash scripts/ensure_state_bucket.sh)"
terraform init -backend-config="bucket=${TF_STATE_BUCKET}"
terraform destroy
```

Confirma la cuenta con `aws sts get-caller-identity` antes de destruir. Se eliminan EC2 y el bucket de artefactos; el bucket de estado y el bootstrap OIDC permanecen.

El workflow manual **CD → Run workflow → destroy** también está disponible si `.github/workflows/cd.yml` existe en la rama predeterminada del repositorio.
