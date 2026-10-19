# Laboratorio AWS IaC — Terraform + GitHub Actions

## Arquitectura
GitHub Actions (OIDC) → Terraform → EC2 (Nginx), S3 privado y CloudWatch Log Group. Estado remoto S3 con lockfile.

## Requisitos
Cuenta AWS con permisos para bootstrap, AWS CLI autenticada, Terraform >= 1.10 (para `use_lockfile`), repositorio GitHub, VPC por defecto y subnet pública con salida a Internet en us-east-1. No subir credenciales.

## Preparación
1. Copiar `bootstrap/terraform.tfvars.example` a `bootstrap/terraform.tfvars` y completar owner, repo y bucket único.
2. `cd bootstrap && terraform init && terraform apply`. Guardar `role_arn` y `state_bucket`. El bootstrap conserva **estado local**: guardarlo de manera segura y no subirlo al repositorio.
3. En GitHub > Settings > Secrets and variables > Actions:
   - Secrets: `AWS_ROLE_ARN`, `TF_STATE_BUCKET`.
   - Variables: `LAB_BUCKET_NAME` (único globalmente), `LAB_HTTP_CIDR` (tu IP pública `/32`).
4. Copiar `infra/terraform.tfvars.example` a `infra/terraform.tfvars` para pruebas locales, con el mismo bucket/CIDR que en GitHub. **No versionar este archivo.**
5. Subir a `develop`. En PR corre fmt/init/validate sin credenciales. En push a `develop` se ejecuta plan/apply con OIDC.
6. Para probar local: `cd infra && terraform init -backend-config="bucket=BUCKET_ESTADO" -backend-config="region=us-east-1" && terraform plan`.

## Experimentos para clase
- A: Cambiar `instance_type` de `t3.micro` a `t3.small` en `infra/variables.tf` (verificar costos). Plan mostrará actualización y posible parada/reinicio.
- B: Cambiar `environment` de `dev` a `qa`: cambia tags y nombres; CloudWatch log group se reemplaza y la SG puede cambiar; revisar `plan` antes de aprobar.
- C: Cambiar `log_retention_days` de 7 a 14: actualización in-place del log group.
- D: Cambiar `bucket_name` en variable de GitHub: S3 no se renombra, Terraform propondrá reemplazo; si hay objetos, puede fallar el destroy. No ejecutar sin discutirlo.
- E: Modificar `user_data` para cambiar texto HTML: normalmente EC2 se detiene/inicia; consultar plan y efecto de IP pública.

## Destruir
GitHub > Actions > Terraform AWS - laboratorio > Run workflow, rama `develop`, operation `destroy`, confirmation `DESTROY`. Vaciar bucket de datos y versiones antes si contiene objetos. **No destruir bootstrap hasta que el estado de infra haya sido destruido.**

## Seguridad y costos
- EC2 y EBS generan cargos, S3 y CloudWatch pueden generar cargos; revisar precios y presupuesto AWS antes de comenzar.
- Puerto 80 es HTTP de demostración, restringido a `LAB_HTTP_CIDR`; no usar en producción. No hay SSH (22) abierto. La IP pública puede cambiar en reinicios.
- S3 bloquea acceso público y cifra datos; CloudWatch log group es un recurso demostrativo, **no recibe logs de Nginx automáticamente**.
- Política IAM del rol del laboratorio es deliberadamente amplia para EC2 y CloudWatch; ajustar a mínimo privilegio para producción.
- `terraform destroy` no borra por sí solo buckets con objetos/versiones; no usar `force_destroy` por seguridad.
- No ejecutar dos applies simultáneos; S3 lockfile protege el estado.
