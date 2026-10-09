# Laboratorio CI/CD: GitHub Actions, Terraform y EC2

Archivos de la guia del 08/10/2026. Un PR valida; un push a develop despliega una pagina HTML en Nginx sobre EC2. AWS se autentica mediante OIDC y la publicacion usa SSM, sin SSH.

Repositorio: `Damianca/devops-ia-2026`. Rama de validacion y despliegue: `develop`.

```bash
git clone https://github.com/Damianca/devops-ia-2026.git
cd devops-ia-2026
git fetch origin
# Si develop ya existe:
git switch develop
# Si aun no existe, usar en su lugar:
# git switch -c develop
```

## Requisitos

Cuenta AWS de laboratorio, GitHub.com, Git, AWS CLI v2, Python 3 y Terraform 1.13.5. Los recursos generan cargos. El ejemplo publica por HTTP y tiene permisos amplios de EC2: usar una cuenta de laboratorio.

## Configuracion inicial (respetar este orden)

1. Usar el repositorio https://github.com/Damianca/devops-ia-2026 y crear o seleccionar la rama develop. Copiar el contenido de esta carpeta a la raiz del repositorio (no la carpeta contenedora). Subir **solamente** `.github/workflows/oidc-info.yml` en el primer commit. No subir aun pipeline.yml: un push a develop ya intenta desplegar.
2. En Actions ejecutar `OIDC - ver subject` desde develop. Copiar el valor exacto de `sub`.
3. Copiar `bootstrap/terraform.tfvars.example` a `bootstrap/terraform.tfvars`. Cambiar bucket_name por un nombre globalmente unico, en minusculas, y pegar el subject real en github_subject.
4. Autenticarse localmente en AWS (por ejemplo AWS SSO) y confirmar la cuenta con `aws sts get-caller-identity`.
5. Ejecutar desde la raiz:

```bash
terraform -chdir=bootstrap init
terraform fmt -recursive
terraform -chdir=bootstrap validate
terraform -chdir=bootstrap plan -out=tfplan
terraform -chdir=bootstrap apply tfplan
terraform -chdir=bootstrap output
```

Si el proveedor OIDC `token.actions.githubusercontent.com` ya existe, importarlo antes de plan/apply con su ARN real:

```bash
terraform -chdir=bootstrap import aws_iam_openid_connect_provider.github arn:aws:iam::TU_CUENTA:oidc-provider/token.actions.githubusercontent.com
```

Conservar privado el state local de bootstrap; no eliminarlo ni subirlo a Git. No destruir un proveedor OIDC compartido.

6. En GitHub > Settings > Secrets and variables > Actions > Variables crear:

| Variable | Valor |
| --- | --- |
| AWS_REGION | us-east-1 (igual que bootstrap) |
| STATE_BUCKET | salida bucket_name de bootstrap |
| AWS_ROLE_ARN | salida github_role_arn de bootstrap |

7. Preparar y validar los archivos antes de subir el resto:

```bash
terraform -chdir=infra init -backend=false
terraform fmt -recursive
terraform -chdir=bootstrap validate
terraform -chdir=infra validate
bash -n scripts/deploy.sh infra/user-data.sh
GITHUB_SHA=0000000000000000000000000000000000000000 python3 scripts/build.py
git add .
git status
git commit -m "Agregar pipeline CI CD e infraestructura EC2"
git push origin develop
```

Los dos `.terraform.lock.hcl` se generan con init: incluirlos en el commit. No estan precreados en este ZIP. Revisar que no se suban tfstate, terraform.tfvars ni planes. El formato de Terraform recuperado de la guia debe normalizarse con `terraform fmt -recursive` antes del commit.

## Demostracion

Abrir el workflow `CI-CD - Terraform y web`. El job CI valida y genera el artefacto; CD aplica Terraform, publica por SSM y comprueba que el HTTP contiene el SHA correcto. La URL aparece en el resumen del job.

Cambiar un texto de `app/index.html`, abrir PR a develop y hacer merge para mostrar otra version. Mantener el marcador `__COMMIT__`; quitarlo en una rama permite demostrar un fallo de CI.

## Eliminar infraestructura

Actions > CI-CD - Terraform y web > Run workflow > develop > operation=destroy. Elimina la EC2 y la red; conserva bucket, roles, perfil y proveedor OIDC del bootstrap. La limpieza completa de bootstrap esta explicada en la guia PDF. Evitar nuevos pushes si ya se termino el laboratorio.

## Validacion del ZIP

Se verificaron la estructura YAML de los workflows, la sintaxis Bash y la generacion del HTML. No se ejecuto Terraform ni un despliegue AWS en este entorno. Ejecutar los comandos de formato y validacion anteriores antes de publicar.
