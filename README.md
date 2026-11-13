# Pipeline CI/CD en AWS — EC2 + Nginx con Terraform y GitHub Actions

**Alumno:** Pablo Santalucia · **Repo:** `Damianca/devops-ia-2026` · **Rama:** `develop_santalucia` · **Región:** `us-east-1`

Un cambio en `develop_santalucia` valida el proyecto (CI), crea/actualiza una EC2 con Terraform y
publica la página HTML en Nginx a través de AWS Systems Manager (CD), verificando el resultado por HTTP.

```
 PR → develop_santalucia            push → develop_santalucia / manual "deploy"        manual "destroy"
 ┌──────────────┐                   ┌──────────────┐   ┌──────────────────────────────┐   ┌───────────────┐
 │      CI      │                   │      CI      │──▶│              CD              │   │    destroy    │
 │ fmt/validate │                   │ (igual)      │   │ OIDC → plan → apply          │   │ OIDC → tf     │
 │ shellcheck   │                   │ artefacto    │   │ artefacto → S3 → SSM → Nginx │   │ destroy       │
 │ build + art. │                   └──────────────┘   │ verificación HTTP (commit)   │   └───────────────┘
 └──────────────┘                                      └──────────────────────────────┘
```

## Estructura

| Ruta | Contenido |
|---|---|
| `app/index.html` | Página propia. Incluye placeholders (`__COMMIT_SHA__`, etc.) que se completan en el build. |
| `scripts/validate.sh` | ShellCheck de scripts + validación básica del HTML. |
| `scripts/build.sh` | Genera `dist/` con commit, rama, run y fecha; crea `version.txt`. |
| `scripts/wait-ssm.sh` | Espera a que la EC2 esté *Online* en SSM. |
| `scripts/deploy-ssm.sh` | Ejecuta en la EC2 (Run Command): descarga el artefacto de S3 y lo publica en Nginx. |
| `scripts/verify-http.sh` | Comprueba por HTTP que la web sirve el commit desplegado. |
| `infra/` | Terraform del laboratorio: EC2 AL2023, Security Group (solo 80), rol IAM con SSM, bucket de artefactos. Backend S3. |
| `bootstrap/` | Terraform que se ejecuta **una vez** en local: bucket de state, proveedor OIDC y rol IAM para GitHub. |
| `.github/workflows/pipeline.yml` | Workflow CI/CD con jobs `ci`, `cd` y `destroy`. |
| `.github/workflows/oidc-info.yml` | Muestra el `sub` del token OIDC para la política de confianza. |

## Requisitos

- Repositorio del curso: `Damianca/devops-ia-2026`, rama `develop_santalucia` (creada desde `develop`).
- Cuenta AWS de laboratorio, AWS CLI v2 autenticada (`aws sts get-caller-identity`).
- Terraform 1.13.5 (mínimo 1.10 por el lock nativo de S3, `use_lockfile`).
- `shellcheck` y `jq` para correr `scripts/validate.sh` en local (`sudo apt install -y shellcheck jq`).

## Configuración inicial (respetar el orden)

### 1. Crear la rama y subir solo el workflow OIDC

```bash
git clone https://github.com/Damianca/devops-ia-2026.git
cd devops-ia-2026
git switch -c develop_santalucia origin/develop
git rm -rq .                                   # la rama arranca limpia: solo archivos propios
unzip ~/pipeline-ec2-santalucia.zip -d .
git add .github/workflows/oidc-info.yml
git commit -m "OIDC: ver subject en develop_santalucia"
git push -u origin develop_santalucia
```

### 2. Obtener el subject OIDC

Actions → **OIDC - ver subject** → *Run workflow* → rama `develop_santalucia`. Copiar el valor exacto de `sub`.
En este repo el subject está personalizado e incluye IDs, por ejemplo
`repo:Damianca@<id>/devops-ia-2026@<id>:ref:refs/heads/develop_santalucia`. No usar el formato
`repo:ORG/REPO:...` porque AWS rechazaría el token.

### 3. Bootstrap (una sola vez, en local)

```bash
cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars
nano bootstrap/terraform.tfvars                # pegar github_subject

aws iam list-open-id-connect-providers         # si ya existe token.actions.githubusercontent.com:
                                               #   create_oidc_provider = false
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan -out=tfplan
terraform -chdir=bootstrap apply tfplan
terraform -chdir=bootstrap output
```

El state del bootstrap queda **local** (`bootstrap/terraform.tfstate`), ignorado por Git. Conservarlo.

### 4. Variables en GitHub

*Settings → Secrets and variables → Actions → Variables*. Como el repo es compartido por todo el curso,
las variables llevan prefijo para no pisar las de otros alumnos:

| Variable | Valor |
|---|---|
| `SANTALUCIA_AWS_ROLE_ARN` | output `aws_role_arn` del bootstrap |
| `SANTALUCIA_STATE_BUCKET` | output `tf_state_bucket` del bootstrap |

No se usan *access keys*: no hay ningún secreto de AWS en GitHub. Mientras `SANTALUCIA_AWS_ROLE_ARN` no exista,
el pipeline corre solo CI y saltea CD.

### 5. Validar en local y subir el resto

```bash
terraform fmt -recursive
terraform -chdir=infra init -backend=false && terraform -chdir=infra validate
terraform -chdir=bootstrap validate
bash scripts/validate.sh
bash scripts/build.sh 0000000 develop_santalucia 0 && rm -rf dist

git add .                     # incluye los dos .terraform.lock.hcl
git status                    # verificar: sin tfstate, tfvars ni planes
git commit -m "Pipeline CI/CD con Terraform, EC2 y Nginx"
git push
```

## Ejecución

| Evento | Qué corre |
|---|---|
| Pull request hacia `develop_santalucia` | Solo **CI** (sin acceso a AWS). |
| Push a `develop_santalucia` | **CI → CD** (plan, apply, deploy por SSM, verificación HTTP). |
| *Run workflow* desde `develop_santalucia`, `operation=deploy` | **CI → CD**. |
| *Run workflow* desde `develop_santalucia`, `operation=destroy` | **destroy**. |

El workflow se llama igual que el de la guía (**CI-CD - Terraform y web**) y vive en el mismo archivo
(`.github/workflows/pipeline.yml`), así aparece en Actions con el botón *Run workflow*; al elegir la rama
`develop_santalucia` GitHub ejecuta la versión de esta rama. Alternativa por CLI:

```bash
gh workflow run pipeline.yml --ref develop_santalucia -f operation=destroy
```

La URL de la web queda en el resumen del job `cd`.

## Demostración

1. **Primera ejecución:** push a `develop_santalucia` → pipeline verde → abrir la URL del resumen.
   La página muestra commit, rama, número de run y fecha de build.
2. **Segundo cambio:** editar `app/index.html` (por ejemplo `v1` → `v2` y el título), push.
   El paso *Verificación HTTP* solo pasa si la web sirve el **nuevo** commit; recargar el navegador para verlo.
3. **Fallo controlado:** romper la validación y hacer push, por ejemplo:
   - borrar la línea `<!DOCTYPE html>` de `app/index.html`, **o**
   - desalinear un `=` en un `.tf` (falla `terraform fmt -check`).

   El job `ci` falla y el job `cd` aparece como **skipped**: no se toca la infraestructura y la web sigue
   mostrando la versión anterior. Revertir el cambio después.
4. **Cierre:** *Run workflow* → rama `develop_santalucia` → `operation=destroy`. El job verifica que el state queda vacío.
   Comprobar también en la consola (EC2, S3, IAM) o con:

   ```bash
   aws ec2 describe-instances --region us-east-1 \
     --filters "Name=tag:Project,Values=santalucia" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
     --query 'Reservations[].Instances[].InstanceId'
   ```

## Explicación

**CI (Integración Continua).** En cada PR y push se valida todo sin desplegar nada: formato y sintaxis de
Terraform (`fmt -check`, `validate` con `-backend=false`, sin credenciales), ShellCheck sobre los scripts y
chequeos del HTML. Si todo pasa, se construye el sitio y se guarda como artefacto.

**CD (Despliegue Continuo).** Solo corre si CI terminó bien (`needs: ci`) y el evento es un push o un deploy manual
en `develop_santalucia`. Ejecuta `terraform plan -out=tfplan` y aplica **ese** plan, sube el artefacto a S3,
espera a que la instancia esté registrada en SSM, ejecuta el despliegue con Run Command y verifica por HTTP
que `version.txt` y la página contienen el SHA del commit.

**Artefacto.** Es el resultado del build (`dist/`: HTML con metadatos + `version.txt`), subido con
`actions/upload-artifact` con nombre `web-<sha>`. CD descarga **ese mismo** artefacto (no vuelve a construir),
así lo que se validó es exactamente lo que se publica. Se copia a S3 (`releases/<sha>.tar.gz`) para que la
EC2 lo descargue con su rol IAM.

**State.** Terraform guarda el estado real de la infraestructura en S3
(`develop_santalucia/ec2-nginx/terraform.tfstate`), con versionado, cifrado y bloqueo nativo (`.tflock`).
Al ser remoto, cada ejecución del pipeline parte del mismo estado; el `concurrency` del workflow evita dos
`apply` simultáneos. El state contiene datos sensibles y por eso nunca va a Git.

**OIDC.** GitHub emite un token firmado por ejecución; AWS lo valida contra el proveedor OIDC y entrega
credenciales temporales del rol `santalucia-github-actions`. La política de confianza exige la audiencia
`sts.amazonaws.com` y el *subject* exacto de `develop_santalucia`, así que ni las ramas de otros alumnos ni
los PR pueden asumir el rol. No hay claves de larga duración que rotar o filtrar.

**Sin SSH.** El Security Group solo abre el puerto 80. La administración y el despliegue van por SSM
(rol `AmazonSSMManagedInstanceCore` en la instancia).

## Qué queda después de `destroy`

`destroy` elimina todo lo de `infra/`: EC2, Security Group y reglas, rol e instance profile de la EC2,
y el bucket de artefactos (`force_destroy`). **Permanecen** los recursos del bootstrap, porque el pipeline
los necesita para poder volver a ejecutarse:

| Recurso | Motivo |
|---|---|
| Bucket `santalucia-tfstate-<cuenta>` (y versiones del state) | Guarda el state; tiene `prevent_destroy`. |
| Proveedor OIDC de GitHub | Compartido a nivel cuenta. |
| Rol `santalucia-github-actions` + política inline | Lo asume el pipeline. |

Para eliminarlos al terminar el curso: quitar `prevent_destroy`, vaciar el bucket (incluidas versiones) y
ejecutar `terraform destroy` en `bootstrap/` (con `create_oidc_provider = false` el proveedor no se borra).

## Seguridad / buenas prácticas

- Sin credenciales ni state en Git (`.gitignore` cubre `*.tfstate`, `*.tfvars`, `.terraform/`, `dist/`).
- IMDSv2 obligatorio, disco cifrado, buckets con *public access block*.
- Permisos del rol de GitHub acotados por prefijo `santalucia-` (IAM/S3) y región `us-east-1` (EC2).

## Troubleshooting

| Síntoma | Causa probable |
|---|---|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | `github_subject` no coincide exactamente con el `sub` del workflow OIDC. |
| `wait-ssm.sh` agota el tiempo | La subred no tiene salida a Internet o la instancia aún está iniciando. |
| `Unsupported: t3.micro in us-east-1e` | Cambiar `availability_zone` en `infra/variables.tf`. |
| Verificación HTTP falla tras deploy OK | Caché del navegador/proxy; probar `curl http://<dns>/version.txt`. |
