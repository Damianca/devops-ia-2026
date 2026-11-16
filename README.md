# DevOPS_Clase11 — AWS IaC con Terraform + GitHub Actions

Rama: **`develop_20oct26_santalucia`** (basada en `develop_20oct26`).
GitHub Actions (OIDC) → Terraform → EC2 (Nginx) + SG, S3 privado y CloudWatch Log Group.
Estado remoto en S3 con lockfile.

## Nombres de recursos

| Recurso | Nombre |
|---|---|
| EC2 (tag Name) | `DevOPS_Clase11-dev-web` |
| Security Group | `DevOPS_Clase11-dev-web-sg-<sufijo>` (tag Name `DevOPS_Clase11-dev-web-sg`) |
| CloudWatch Log Group | `DevOPS_Clase11/dev/app` |
| IAM Role | `DevOPS_Clase11-github-role` |
| Política inline | `DevOPS_Clase11-lab-policy` |
| Key del estado | `DevOPS_Clase11/infra/terraform.tfstate` |
| Bucket de estado | `devops-clase11-tfstate-santalucia` (*) |
| Bucket de datos | `devops-clase11-datos-santalucia` (*) |

(*) S3 no admite mayúsculas ni `_` en el nombre del bucket, por eso `devops-clase11-...`.
Todos los recursos llevan el tag `Project = DevOPS_Clase11`.

## 1. Preparar la rama (en la VM)

```bash
cd ~/devops-ia-2026
git fetch origin
git checkout -b develop_20oct26_santalucia origin/develop_20oct26
# copiar los archivos de esta rama encima y commitear (ver paso 4)
```

## 2. Bootstrap con el usuario IAM `IaC_Terraform`

```bash
aws sts get-caller-identity          # debe mostrar .../user/IaC_Terraform
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
terraform output                     # role_arn y state_bucket
```

- El proveedor OIDC de GitHub se **reutiliza** (ya existe en la cuenta desde el ejercicio
  de `develop_santalucia`). Si el plan dice que no lo encuentra, poner
  `create_oidc_provider = true`.
- El `sub` de OIDC ya viene con el formato real del repo:
  `repo:Damianca@2234442/devops-ia-2026@1317392920:ref:refs/heads/develop_20oct26_santalucia`
- El estado del bootstrap queda **local** (`bootstrap/terraform.tfstate`): guardarlo,
  no subirlo (está en `.gitignore`).
- `IaC_Terraform` necesita permisos de IAM (crear rol y política, leer el proveedor OIDC)
  y de S3.

## 3. Variables en GitHub (Settings → Secrets and variables → Actions → Variables)

Con prefijo propio para no pisar las de otros alumnos:

| Variable | Valor |
|---|---|
| `SANTALUCIA_CLASE11_ROLE_ARN` | output `role_arn` |
| `SANTALUCIA_CLASE11_STATE_BUCKET` | output `state_bucket` |
| `SANTALUCIA_CLASE11_BUCKET_NAME` | `devops-clase11-datos-santalucia` |
| `SANTALUCIA_CLASE11_HTTP_CIDR` | tu IP pública + `/32` (`curl -s ifconfig.me`) |

## 4. Primer despliegue

```bash
cd ~/devops-ia-2026
git add .
git commit -m "DevOPS_Clase11: laboratorio Terraform + GitHub Actions"
git push -u origin develop_20oct26_santalucia
```

El push corre `validate` y luego `deploy` (plan + apply). En el paso **Outputs** está
`web_url`: abrirla desde tu IP. Verificar en la consola AWS (us-east-1): EC2, S3 y
CloudWatch → Log groups.

También se puede correr a mano: Actions → *Terraform AWS - laboratorio* → Run workflow →
rama `develop_20oct26_santalucia` → `plan` / `apply` / `destroy`.

### Prueba local (opcional, desde la VM)

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # completar http_cidr
terraform init -backend-config="bucket=devops-clase11-tfstate-santalucia" -backend-config="region=us-east-1"
terraform plan
```

## Experimentos (un commit por cambio → push → leer el plan en Actions)

| | Cambio | Archivo | Qué muestra el plan |
|---|---|---|---|
| A | `instance_type` t3.micro → t3.small | `infra/variables.tf` | `~` update in-place de la EC2 (stop/start; cambia la IP pública). Revertir |
| B | `environment` dev → qa | `infra/variables.tf` | Log group `-/+` (cambia el nombre), SG `+/-` (create_before_destroy), EC2 `~` (tags y SG). Revertir |
| C | `log_retention_days` 7 → 14 | `infra/variables.tf` | `~` solo el log group; EC2 y S3 sin cambios |
| D | `SANTALUCIA_CLASE11_BUCKET_NAME` → otro nombre | variable de GitHub | Bucket `-/+`: S3 no se renombra. Correr solo `plan` y discutir |
| E | Texto HTML en `user_data` | `infra/main.tf` | `~` EC2 (stop/start); el HTML no se re-ejecuta sin reemplazo |

Para revertir: `git revert <commit>` y push.

## Destruir

1. Si el bucket de datos tiene objetos: vaciarlo con **versiones** (consola S3 → Empty).
2. Actions → Run workflow → rama `develop_20oct26_santalucia` → `destroy` + `DESTROY`.
3. Verificar que no queden EC2, SG, S3 de datos ni log group.
4. Recién después, el bootstrap (vaciar antes el bucket de estado, que tiene versiones):
   `cd bootstrap && terraform destroy`. El proveedor OIDC no se borra porque se reutilizó.

## Actividad evaluativa

1. **¿Qué cambia al modificar el tipo EC2?** Es un update in-place (mismo ID): AWS detiene
   la instancia, cambia el tipo y la arranca. Hay corte de servicio, cambia la IP pública
   (no hay Elastic IP) y cambia el costo por hora.
2. **¿Por qué S3 no se puede renombrar?** El nombre es el identificador global e inmutable
   del bucket; no existe API de rename. Terraform propone destruir y crear otro, y los
   datos hay que migrarlos (`aws s3 sync`). Si tiene objetos/versiones, el destroy falla.
3. **Plan vs apply:** `plan` compara código, estado y realidad y muestra qué haría sin
   tocar nada. `apply` ejecuta los cambios y actualiza el estado. El workflow aplica
   exactamente el plan guardado (`tfplan`), así no hay sorpresas entre uno y otro.
4. **¿Por qué OIDC?** No hay claves de larga duración guardadas en GitHub que se puedan
   filtrar o haya que rotar: cada run recibe credenciales temporales de STS, y la trust
   policy limita qué repo y qué rama pueden asumir el rol.
5. **Commit y su cambio en AWS:** ej. commit del experimento C → en Actions,
   `~ retention_in_days = 7 -> 14` → en CloudWatch, `DevOPS_Clase11/dev/app` muestra
   retención de 14 días.

## Seguridad y costos

- Puerto 80 solo desde tu `/32`; sin SSH. IMDSv2 obligatorio, disco gp3 cifrado.
- S3 con bloqueo público, cifrado AES256 y versionado; sin `force_destroy`.
- Permisos del rol amplios en EC2/Logs (demo); S3 limitado a `devops-clase11-*`.
- El log group no recibe logs de Nginx por sí solo (haría falta el agente de CloudWatch).
- EC2/EBS/S3/CloudWatch generan costos: destruir al terminar.
